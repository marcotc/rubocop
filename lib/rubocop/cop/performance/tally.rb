# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # This cop checks for inefficient implementations of the `group_by+count`
      # pattern: count the number of occurences of each unique element of a list
      # and return a hash where the keys are the list elements and values are the
      # number of occurences.
      #
      # This same logic is implemented efficiently (since Ruby 2.7) by
      # `Enumerable#tally`.
      #
      # @example
      #   # bad
      #   [1, 2, 3].group_by { |x| x }.map { |k, v| [k, v.count] }.to_h
      #   [1, 2, 3].group_by { |x| x }.transform_values { |v| v.length }
      #   [1, 2, 3].inject(Hash.new(0)) { |h, v| h[v] += 1; h }
      #
      #   # good
      #   [1, 2, 3].tally
      #
      #   MARCO! see https://stackoverflow.com/questions/5470725/how-to-group-by-count-in-array-without-using-loop
      #   MARCO! post benchmarks
      class Tally < Cop
        # extend TargetRubyVersion
        include RangeHelp

        # minimum_target_ruby_version 2.7

        MSG = 'Use `tally` to count the occurence items in a list.'.freeze
        DESIRED_METHOD = 'tally'

        def_node_matcher :group_by_map?, <<-PATTERN
          (send
            (block
              (send
                (block
                  (send $_enumerable :group_by)
                  (args
                    (arg _x))
                  (lvar _x)) {:map :map!})
              (args
                (arg _k)
                (arg _v))
              (array
                (lvar _k)
                (send
                  (lvar _v) {:count :length :size}))) :to_h)
        PATTERN

        def_node_matcher :group_by_transform_values?, <<-PATTERN
          (block
            (send
              (block
                (send $_enumerable :group_by)
                (args
                  (arg _x))
                (lvar _x)) {:transform_values :transform_values!})
            (args
              (arg _v))
              (send
                (lvar _v) {:count :length :size}))
        PATTERN


        def_node_matcher :inject?, <<-PATTERN
          (block
            (send $_enumerable {:inject :reduce}
              (send
                (const nil? :Hash) :new
                (int 0)))
            (args
              (arg _h)
              (arg _v))
            (begin
              (op-asgn
                (send
                  (lvar _h) :[]
                  (lvar _v)) :+
                (int 1))
              (lvar _h)))
        PATTERN


      # def on_block_pass(node)
      #   # puts node
      # end

      

      def on_block(node)
        group_by_transform_values?(node) do |selector_node, selector, counter|
          add_offense(node, location: offending_range(selector_node, node),message: MSG)
        end

        inject?(node) do |selector_node, selector, counter|
          add_offense(node, location: offending_range(selector_node, node),message: MSG)
        end
      end

      def on_send(node)
        group_by_map?(node) do |selector_node, selector, counter|
          add_offense(node, location: offending_range(selector_node, node),message: MSG)
        end
      end

        def autocorrect(node)
          ->(corrector) do
            group_by_map?(node) do |selector_node, _, _|
              corrector.replace(offending_range(selector_node, node),
                DESIRED_METHOD)
              # test with line breaks, or weird spacing
              #
              # [].
              # group_by ...
              #
              # []
              # .group_by ...
              #
              # [] . group_by ...
            end

            group_by_transform_values?(node) do |selector_node, _, _|
              corrector.replace(offending_range(selector_node, node), DESIRED_METHOD)
            end

            inject?(node) do |selector_node, _, _|
              puts selector_node
              corrector.replace(offending_range(selector_node, node), DESIRED_METHOD)
            end
          end
        end

        private

        # TODO I feel like I might be doing this wrong if I always have to fix Range
        def offending_range(enumerable_node, node)
          Parser::Source::Range.new(
            node.source_range.source_buffer,
            enumerable_node.parent.loc.dot.end_pos,
            node.loc.expression.end_pos)
        end
      end
    end
  end
end
