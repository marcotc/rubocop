# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Performance::Tally do
  subject(:cop) { described_class.new }

  it 'mismatching #group_by' do
    expect_no_offenses('[].group_by{|x|x % 2}.map{|k,v|[k,v.size]}.to_h')
  end

  it 'mismatching #map' do
    expect_no_offenses('[].group_by{|x|x}.map{|k,v|[k,v]}.to_h')
    expect_no_offenses('[].group_by{|x|x}.map{|k,v|v.size}.to_h')
  end


  it 'matches Array[] inside #map' do
    # TODO Should I care about this case? Is it relevant?
    expect_offense('[].group_by{|x|x}.map{|k,v|Array[k,v.size]}.to_h')
  end

  it 'bad #group_by+#map+#to_h' do
    expect_offense(<<-RUBY.strip_indent)
      [].group_by{|x|x}.map{|k,v|[k,v.size]}.to_h
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ TEST!
    RUBY
  end

  it 'bad Hash[#group_by+#map]' do
    expect_offense(<<-RUBY.strip_indent)
      Hash[[].group_by{|x|x}.map{|k,v|[k,v.size]}]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ TEST!
    RUBY
  end

  context 'autocorrect' do
    context 'will correct' do
      it 'select..size to count' do
        new_source = autocorrect_source('[:foo].group_by{|x|x}.map{|k,v|[k,v.size]}.to_h')

        expect(new_source).to eq('[:foo].tally')
      end
    end
  end
end
