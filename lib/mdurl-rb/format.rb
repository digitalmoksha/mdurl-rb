module MDUrl
  module Format

    #------------------------------------------------------------------------------
    def self.format(url)
      result = ''

      result += url.protocol || ''
      result += url.slashes ? '//' : ''
      result += url.auth ? url.auth + '@' : ''

      if (url.hostname && url.hostname.index(':') != nil)
        # ipv6 address
        result += '[' + url.hostname + ']'
      else
        result += url.hostname || ''
      end

      result += url.port ? ':' + url.port : ''
      result += url.pathname || ''
      result += url.search || ''
      result += url.hash || ''

      return result
    end
    
  end
end
