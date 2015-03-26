def encodeBinary(str)
  result = ''

  str = str.gsub(/\s+/, '')
  while (str.length > 0)
    result = '%' + ('0' + str.slice(-8..-1).to_i(2).to_s(16)).slice(-2, 2) + result
    str = str.slice(0...-8)
  end

  return result
end

samples = {
  '00000000' => true,
  '01010101' => true,
  '01111111' => true,

  # invalid as 1st byte
  '10000000' => false,
  '10111111' => false,

  # invalid sequences, 2nd byte should be >= 0x80
  '11000111 01010101' => false,
  '11100011 01010101' => false,
  '11110001 01010101' => false,

  # invalid sequences, 2nd byte should be < 0xc0
  '11000111 11000000' => false,
  '11100011 11000000' => false,
  '11110001 11000000' => false,

  # invalid 3rd byte
  '11100011 10010101 01010101' => false,
  '11110001 10010101 01010101' => false,

  # invalid 4th byte
  '11110001 10010101 10010101 01010101' => false,

  # valid sequences
  '11000111 10101010' => true,
  '11100011 10101010 10101010' => true,
  # '11110001 10101010 10101010 10101010' => true,   # TODO don't know how to handle surrogate pairs

  # minimal chars with given length
  '11000010 10000000' => true,
  '11100000 10100000 10000000' => true,

  # impossible sequences
  '11000001 10111111' => false,
  '11100000 10011111 10111111' => false,
  '11000001 10000000' => false,
  '11100000 10010000 10000000' => false,

  # maximum chars with given length
  '11011111 10111111' => true,
  '11101111 10111111 10111111' => true,

  # '11110000 10010000 10000000 10000000' => true,   # TODO don't know how to handle surrogate pairs
  # '11110000 10010000 10001111 10001111' => true,   # TODO don't know how to handle surrogate pairs
  # '11110100 10001111 10110000 10000000' => true,   # TODO don't know how to handle surrogate pairs
  # '11110100 10001111 10111111 10111111' => true,   # TODO don't know how to handle surrogate pairs

  # too low
  '11110000 10001111 10111111 10111111' => false,

  # too high
  '11110100 10010000 10000000 10000000' => false,
  '11110100 10011111 10111111 10111111' => false,

  # surrogate range
  '11101101 10011111 10111111' => true,
  '11101101 10100000 10000000' => false,
  '11101101 10111111 10111111' => false,
  '11101110 10000000 10000000' => true
}

describe 'decode' do
  it 'should decode %xx' do
    expect(MDUrl::Decode.decode('x%20xx%20%2520')).to eq 'x xx %20'
  end

  it 'should not decode invalid sequences' do
    expect(MDUrl::Decode.decode('%2g%z1%%')).to eq '%2g%z1%%'
  end

  it 'should not decode reservedSet' do
    expect(MDUrl::Decode.decode('%20%25%20', '%')).to eq  ' %25 '
    expect(MDUrl::Decode.decode('%20%25%20', ' ')).to eq  '%20%%20'
    expect(MDUrl::Decode.decode('%20%25%20', ' %')).to eq '%20%25%20'
  end

  describe 'utf8' do
    samples.each_pair do |k, v|

      it "#{k}" do
        er = nil
        str = encodeBinary(k)

        if v == true
          res1 = CGI::unescape(str, Encoding::UTF_8)
          res2 = MDUrl::Decode.decode(str)
          expect(res1).to eq res2
          expect(res2.index("\ufffd")).to eq nil
        else
          res2 = MDUrl::Decode.decode(str)
          expect(res2.index("\ufffd")).not_to eq nil
        end
      end
    end
  end
end
