describe 'format' do
  URL_TEST_DATA.each_pair do |url, result|

    it "#{url}" do
      parsed = MDUrl::Url.urlParse(url)
      expect(MDUrl::Format.format(parsed)).to eq url
    end
  end
end
