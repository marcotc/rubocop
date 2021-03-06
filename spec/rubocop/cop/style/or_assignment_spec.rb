# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::OrAssignment do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  context 'when using var = var ? var : something' do
    it 'registers an offense with normal variables' do
      expect_offense(<<-RUBY.strip_indent)
        foo = foo ? foo : 'default'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
      RUBY
    end

    it 'registers an offense with instance variables' do
      expect_offense(<<-RUBY.strip_indent)
        @foo = @foo ? @foo : 'default'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
      RUBY
    end

    it 'registers an offense with class variables' do
      expect_offense(<<-RUBY.strip_indent)
        @@foo = @@foo ? @@foo : 'default'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
      RUBY
    end

    it 'registers an offense with global variables' do
      expect_offense(<<-RUBY.strip_indent)
        $foo = $foo ? $foo : 'default'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
      RUBY
    end

    it 'autocorrects normal variables to `var ||= something`' do
      expect(autocorrect_source('x = x ? x : 3')).to eq('x ||= 3')
    end

    it 'autocorrects instance variables to `var ||= something`' do
      expect(autocorrect_source('@x = @x ? @x : 3')).to eq('@x ||= 3')
    end

    it 'autocorrects class variables to `var ||= something`' do
      expect(autocorrect_source('@@x = @@x ? @@x : 3')).to eq('@@x ||= 3')
    end

    it 'autocorrects global variables to `var ||= something`' do
      expect(autocorrect_source('$x = $x ? $x : 3')).to eq('$x ||= 3')
    end

    it 'does not register an offense if any of the variables are different' do
      expect_no_offenses('foo = bar ? foo : 3')
      expect_no_offenses('foo = foo ? bar : 3')
    end
  end

  context 'when using var = if var; var; else; something; end' do
    it 'registers an offense with normal variables' do
      expect_offense(<<-RUBY.strip_indent)
        foo = if foo
        ^^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
                foo
              else
                'default'
              end
      RUBY
    end

    it 'registers an offense with instance variables' do
      expect_offense(<<-RUBY.strip_indent)
        @foo = if @foo
        ^^^^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
                 @foo
               else
                 'default'
               end
      RUBY
    end

    it 'registers an offense with class variables' do
      expect_offense(<<-RUBY.strip_indent)
        @@foo = if @@foo
        ^^^^^^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
                  @@foo
                else
                  'default'
                end
      RUBY
    end

    it 'registers an offense with global variables' do
      expect_offense(<<-RUBY.strip_indent)
        $foo = if $foo
        ^^^^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
                 $foo
               else
                 'default'
               end
      RUBY
    end

    it 'autocorrects normal variables to `var ||= something`' do
      expect(autocorrect_source(<<-RUBY.strip_indent)).to eq("x ||= 3\n")
        x = if x
              x
            else
              3
            end
      RUBY
    end

    it 'autocorrects instance variables to `var ||= something`' do
      expect(autocorrect_source(<<-RUBY.strip_indent)).to eq("@x ||= 3\n")
        @x = if @x
               @x
             else
               3
             end
      RUBY
    end

    it 'autocorrects class variables to `var ||= something`' do
      expect(autocorrect_source(<<-RUBY.strip_indent)).to eq("@@x ||= 3\n")
        @@x = if @@x
                @@x
              else
                3
              end
      RUBY
    end

    it 'autocorrects global variables to `var ||= something`' do
      expect(autocorrect_source(<<-RUBY.strip_indent)).to eq("$x ||= 3\n")
        $x = if $x
               $x
             else
               3
             end
      RUBY
    end

    it 'does not register an offense if any of the variables are different' do
      expect_no_offenses(<<-RUBY.strip_indent)
        foo = if foo
                bar
              else
                3
              end
      RUBY
      expect_no_offenses(<<-RUBY.strip_indent)
        foo = if bar
                foo
              else
                3
              end
      RUBY
    end
  end

  context 'when using var = something unless var' do
    it 'registers an offense for normal variables' do
      expect_offense(<<-RUBY.strip_indent)
        foo = 'default' unless foo
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
      RUBY
    end

    it 'registers an offense for instance variables' do
      expect_offense(<<-RUBY.strip_indent)
        @foo = 'default' unless @foo
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
      RUBY
    end

    it 'registers an offense for class variables' do
      expect_offense(<<-RUBY.strip_indent)
        @@foo = 'default' unless @@foo
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
      RUBY
    end

    it 'registers an offense for global variables' do
      expect_offense(<<-RUBY.strip_indent)
        $foo = 'default' unless $foo
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
      RUBY
    end

    it 'autocorrects normal variables to `var ||= something`' do
      expect(autocorrect_source('x = 3 unless x')).to eq('x ||= 3')
    end

    it 'autocorrects instance variables to `var ||= something`' do
      expect(autocorrect_source('@x = 3 unless @x')).to eq('@x ||= 3')
    end

    it 'autocorrects class variables to `var ||= something`' do
      expect(autocorrect_source('@@x = 3 unless @@x')).to eq('@@x ||= 3')
    end

    it 'autocorrects global variables to `var ||= something`' do
      expect(autocorrect_source('$x = 3 unless $x')).to eq('$x ||= 3')
    end

    it 'does not register an offense if any of the variables are different' do
      expect_no_offenses('foo = 3 unless bar')
      expect_no_offenses(<<-RUBY.strip_indent)
        unless foo
          bar = 3
        end
      RUBY
    end
  end

  context 'when using unless var; var = something; end' do
    it 'registers an offense for normal variables' do
      expect_offense(<<-RUBY.strip_indent)
        foo = nil
        unless foo
        ^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
          foo = 'default'
        end
      RUBY
    end

    it 'registers an offense for instance variables' do
      expect_offense(<<-RUBY.strip_indent)
        @foo = nil
        unless @foo
        ^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
          @foo = 'default'
        end
      RUBY
    end

    it 'registers an offense for class variables' do
      expect_offense(<<-RUBY.strip_indent)
        @@foo = nil
        unless @@foo
        ^^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
          @@foo = 'default'
        end
      RUBY
    end

    it 'registers an offense for global variables' do
      expect_offense(<<-RUBY.strip_indent)
        $foo = nil
        unless $foo
        ^^^^^^^^^^^ Use the double pipe equals operator `||=` instead.
          $foo = 'default'
        end
      RUBY
    end

    it 'autocorrects normal variables to `var ||= something`' do
      new_source_normal = autocorrect_source(<<-RUBY.strip_indent)
        foo = nil
        unless foo
          foo = 3
        end
      RUBY
      expect(new_source_normal).to eq("foo = nil\nfoo ||= 3\n")
    end

    it 'autocorrects instance variables to `var ||= something`' do
      new_source_instance = autocorrect_source(<<-RUBY.strip_indent)
        @foo = nil
        unless @foo
          @foo = 3
        end
      RUBY
      expect(new_source_instance).to eq("@foo = nil\n@foo ||= 3\n")
    end

    it 'autocorrects class variables to `var ||= something`' do
      new_source_class = autocorrect_source(<<-RUBY.strip_indent)
        @@foo = nil
        unless @@foo
          @@foo = 3
        end
      RUBY
      expect(new_source_class).to eq("@@foo = nil\n@@foo ||= 3\n")
    end

    it 'autocorrects global variables to `var ||= something`' do
      new_source_global = autocorrect_source(<<-RUBY.strip_indent)
        $foo = nil
        unless $foo
          $foo = 3
        end
      RUBY
      expect(new_source_global).to eq("$foo = nil\n$foo ||= 3\n")
    end

    it 'does not register an offense if any of the variables are different' do
      expect_no_offenses(<<-RUBY.strip_indent)
        unless foo
          bar = 3
        end
      RUBY
    end
  end
end
