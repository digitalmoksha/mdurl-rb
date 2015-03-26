describe 'parse' do
  
  URL_TEST_DATA.each_pair do |url, result|

    it "#{url}" do
      parsed = MDUrl::Url.urlParse(url)

      (expect(parsed.protocol).to eq result['protocol']) if parsed.protocol
      (expect(parsed.slashes).to  eq result['slashes'])  if parsed.slashes
      (expect(parsed.hostname).to eq result['hostname']) if parsed.hostname
      (expect(parsed.pathname).to eq result['pathname']) if parsed.pathname
    end

  end
end