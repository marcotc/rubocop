# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Performance::Tally do
  subject(:cop) { described_class.new }

  context 'with #group_by { |x| x }' do
    it 'mismatching #group_by' do
      expect_no_offenses('[0].group_by{|x|x % 2}.map{|k,v|[k,v.size]}.to_h')
    end

    context 'with #map{...}.to_h' do
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

      # @words.group_by { |w| w }
      # .map { |k, v| [k, v.length] }

      it 'will correct' do
        new_source = autocorrect_source('[0].group_by{|x|x}.map{|k,v|[k,v.size]}.to_h')
        expect(new_source).to eq('[0].tally')
      end
    end

    context 'with #transform_values' do
      %w(count length size).each do |sizer|
        context "with ##{sizer}" do
          it 'registers an offense' do
            expect_offense(<<-RUBY.strip_indent)
              [0].group_by { |x| x }.transform_values { |v| v.#{'%17s' % sizer} }
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ TEST!
            RUBY
          end
        end
      end

      it 'will correct' do
        new_source = autocorrect_source('[0].group_by{|x|x}.transform_values{|v|v.size}')
        expect(new_source).to eq('[0].tally')
      end
    end
  end

  context 'with #inject/#reduce' do
    it 'registers an offense' do
      expect_offense(<<-RUBY.strip_indent)
        [0].inject(Hash.new(0)){|h,v|h[v]+=1;h}
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ TEST!
      RUBY
    end

    it 'will correct' do
      new_source = autocorrect_source('[0].inject(Hash.new(0)){|h,v|h[v]+=1;h}')
      expect(new_source).to eq('[0].tally')
    end
  end

  xit 'bad #group_by+#map+#to_h' do
    expect_offense(<<-RUBY.strip_indent)
      [0].group_by{|x|x}.map{|k,v|[k,v.size]}.to_h
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ TEST!
    RUBY
  end
end
