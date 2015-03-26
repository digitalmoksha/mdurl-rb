describe 'encode' do

  it 'should encode percent' do
    expect(MDUrl::Encode.encode("%%%")).to eq '%25%25%25'
  end

  it 'should encode control chars' do
    expect(MDUrl::Encode.encode("\r\n")).to eq '%0D%0A'
  end

  it 'should not encode parts of an url' do
    expect(MDUrl::Encode.encode('?#')).to eq '?#'
  end

  it 'should not encode []^ - commonmark tests' do
    expect(MDUrl::Encode.encode('[]^')).to eq '%5B%5D%5E'
  end

  it 'should encode spaces' do
    expect(MDUrl::Encode.encode('my url')).to eq 'my%20url'
  end

  it 'should encode unicode' do
    expect(MDUrl::Encode.encode('φου')).to eq '%CF%86%CE%BF%CF%85'
  end

  it 'should encode % if it doesn\'t start a valid escape seq' do
    expect(MDUrl::Encode.encode('%FG')).to eq '%25FG'
  end

  it 'should preserve non-utf8 encoded characters' do
    expect(MDUrl::Encode.encode('%00%FF')).to eq '%00%FF'
  end

  # it 'should encode characters on the cache borders' do
  #   # protects against off-by-one in cache implementation
  #   expect(MDUrl::Encode.encode("\x00\x7F\x80")).to eq '%00%7F%C2%80'
  # end

  describe 'arguments' do
    it 'encode(string, unescapedSet)' do
      expect(MDUrl::Encode.encode('!@#$', '@$')).to eq '%21@%23$'
    end

    it 'encode(string, keepEscaped=true)' do
      expect(MDUrl::Encode.encode('%20%2G', true)).to eq '%20%252G'
    end

    it 'encode(string, keepEscaped=false)' do
      expect(MDUrl::Encode.encode('%20%2G', false)).to eq '%2520%252G'
    end

    it 'encode(string, unescapedSet, keepEscaped)' do
      expect(MDUrl::Encode.encode('!@%25', '@', false)).to eq '%21@%2525'
    end
  end

  # TODO don't know how to fix utf8 issue yet
  # describe 'surrogates' do
  #   it 'bad surrogates (high)' do
  #     expect(MDUrl::Encode.encode("\uD800foo")).to eq '%EF%BF%BDfoo'
  #     expect(MDUrl::Encode.encode("foo\uD800")).to eq 'foo%EF%BF%BD'
  #   end
  #
  #   it 'bad surrogates (low)' do
  #     expect(MDUrl::Encode.encode("\uDD00foo")).to eq '%EF%BF%BDfoo'
  #     expect(MDUrl::Encode.encode("foo\uDD00")).to eq 'foo%EF%BF%BD'
  #   end
  #
  #   it 'valid one' do
  #     expect(MDUrl::Encode.encode("\uD800\uDD00")).to eq '%F0%90%84%80'
  #   end
  # end
end
