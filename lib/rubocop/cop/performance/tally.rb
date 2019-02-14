# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # This cop is used to identify usages of `count` on an `Enumerable` that
      # follow calls to `select` or `reject`. Querying logic can instead be
      # passed to the `count` call.
      #
      # @example
      #   # bad
      #   [1, 2, 3].select { |e| e > 2 }.size
      #   [1, 2, 3].reject { |e| e > 2 }.size
      #   [1, 2, 3].select { |e| e > 2 }.length
      #   [1, 2, 3].reject { |e| e > 2 }.length
      #   [1, 2, 3].select { |e| e > 2 }.count { |e| e.odd? }
      #   [1, 2, 3].reject { |e| e > 2 }.count { |e| e.even? }
      #   array.select(&:value).count
      #
      #   # good
      #   [1, 2, 3].count { |e| e > 2 }
      #   [1, 2, 3].count { |e| e < 2 }
      #   [1, 2, 3].count { |e| e > 2 && e.odd? }
      #   [1, 2, 3].count { |e| e < 2 && e.even? }
      #   Model.select('field AS field_one').count
      #   Model.select(:value).count
      #
      # `ActiveRecord` compatibility:
      # `ActiveRecord` will ignore the block that is passed to `count`.
      # Other methods, such as `select`, will convert the association to an
      # array and then run the block on the array. A simple work around to
      # make `count` work with a block is to call `to_a.count {...}`.
      #
      # Example:
      #   arr.group_by { |x| x }.map { |k, v| [k, v.count] }.to_h
      #   arr.group_by { |x| x }.transform_values { |v| v.length }
      #   arr.group_by(&:itself).map { |k, v| [k, v.size] }.to_h
      #   Hash[arr.group_by { |x| x }.map { |k, v| [k, v.size] }]
      #
      #   arr.inject(Hash.new(0)) { |h, v| h[v] += 1; h }
      #   arr.each_with_object(Hash.new(0)) { |v, h| h[v] += 1 }
      #
      #   MARCO! see https://stackoverflow.com/questions/5470725/how-to-group-by-count-in-array-without-using-loop
      #
      #   becomes:
      #
      #   arr.tally
      class Tally < Cop
        # extend TargetRubyVersion
        include RangeHelp

        # minimum_target_ruby_version 2.7

        MSG = 'Use `count` instead of `%<selector>s...%<counter>s`.'.freeze

        def_node_matcher :group_by_map?, <<-PATTERN
          {
            (block
              (send
                (block
                  (send (_ :group_by) (args (arg $_x)) (lvar $_x))
                  :map) (args (arg $_k) (arg $_v)) (array (lvar $_k) (send (lvar $_v) :size))
              ) 
            :to_h)
          }
        PATTERN

        def_node_matcher :group_by_map_1?, <<-PATTERN
          (send
            (block
              (send
                (block
                  (send _ :group_by)
                  (args
                    (arg $_x))
                  (lvar $_x)) {:map :map!})
              (args
                (arg $_k)
                (arg $_v))
              (array
                (lvar $_k)
                (send
                  (lvar $_v) {:count :length :size}))) :to_h)
        PATTERN

        def on_send(node)
          group_by_map_1?(node) do |selector_node, selector, counter|
            # return unless eligible_node?(node)
            #
            # range = source_starting_at(node) do
            #   selector_node.loc.selector.begin_pos
            # end

            add_offense(node,
                        message: 'TEST!'
                        # location: range,
                        # message: format(MSG, selector: selector,
                        #                      counter: counter))
            )
          end
        end

        def autocorrect(node)
          a=1
          # selector_node, selector, _counter = count_candidate?(node)
          # selector_loc = selector_node.loc.selector
          #
          # return if selector == :reject
          #
          # range = source_starting_at(node) { |n| n.loc.dot.begin_pos }
          #
          # lambda do |corrector|
          #   corrector.remove(range)
          #   corrector.replace(selector_loc, 'count')
          # end
        end

        private

        def eligible_node?(node)
          !(node.parent && node.parent.block_type?)
        end

        def source_starting_at(node)
          begin_pos = if block_given?
                        yield node
                      else
                        node.source_range.begin_pos
                      end

          range_between(begin_pos, node.source_range.end_pos)
        end
      end
    end
  end
end
