# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Performance::Tally do
  subject(:cop) { described_class.new }

  context 'with #group_by' do
    it 'mismatching #group_by' do
      expect_no_offenses('[].group_by{|x|x % 2}.map{|k,v|[k,v.size]}.to_h')
    end

    context 'with #map' do
      context 'with #to_h' do
        it 'with mismatching #map block' do
          expect_no_offenses('[0].group_by{|x|x}.map{|k,v|[k,v]}.to_h')
          expect_no_offenses('[0].group_by{|x|x}.map{|k,v|v.size}.to_h')
        end

        %w(count length size).each do |sizer|
          context "with ##{sizer}" do
            it 'registers an offense' do
              expect_offense(<<-RUBY.strip_indent)
                [0].group_by { |x| x }.map { |k, v| [k, v.#{'%17s' % sizer}] }.to_h
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ TEST!
              RUBY
            end
          end
        end

        it 'will correct' do
          new_source = autocorrect_source('[0].group_by{|x|x}.map{|k,v|[k,v.size]}.to_h')
          expect(new_source).to eq('[0].tally')
        end
      end
    end

    context 'with Hash.[]' do
      it 'mismatching #map' do
        expect_no_offenses('[0].group_by{|x|x}.map{|k,v|[k,v]}.to_h')
        expect_no_offenses('[0].group_by{|x|x}.map{|k,v|v.size}.to_h')
      end
    end
  end

  context 'with #transform_values' do

  end

  context 'with #inject/#reduce' do

  end

  context 'with #each_with_object' do

  end

  it 'matches Array[] inside #map' do
    # TODO Should I care about this case? Is it relevant?
    expect_offense(<<-RUBY.strip_indent)
      [0].group_by{|x|x}.map{|k,v|Array[k,v.size]}.to_h
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ TEST!
    RUBY
  end

  it 'bad #group_by+#map+#to_h' do
    expect_offense(<<-RUBY.strip_indent)
      [0].group_by{|x|x}.map{|k,v|[k,v.size]}.to_h
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ TEST!
    RUBY
  end

  it 'bad Hash[#group_by+#map]' do
    expect_offense(<<-RUBY.strip_indent)
      Hash[[0].group_by{|x|x}.map{|k,v|[k,v.size]}]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ TEST!
    RUBY
  end
end
