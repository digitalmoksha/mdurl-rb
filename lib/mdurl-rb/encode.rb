module MDUrl
  module Encode

    DEFAULT_CHARACTERS   = ";/?:@&=+$,-_.!~*'()#"
    COMPONENT_CHARACTERS = "-_.!~*'()"

    @@encodeCache = {}


    # Create a lookup array where anything but characters in `chars` string
    # and alphanumeric chars is percent-encoded.
    #------------------------------------------------------------------------------
    def self.getEncodeCache(exclude)
      cache = @@encodeCache[exclude]
      return cache if (cache)

      cache = @@encodeCache[exclude] = []

      (0...128).each do |i|
        ch = i.chr

        if (/^[0-9a-z]$/i =~ ch)
          # always allow unencoded alphanumeric characters
          cache.push(ch)
        else
          cache.push('%' + ('0' + i.to_s(16).upcase).slice(-2, 2))
        end
      end

      (0...exclude.length).each do |i|
        cache[exclude[i].ord] = exclude[i]
      end

      return cache
    end


    # Encode unsafe characters with percent-encoding, skipping already
    # encoded sequences.
    #
    #  - string       - string to encode
    #  - exclude      - list of characters to ignore (in addition to a-zA-Z0-9)
    #  - keepEscaped  - don't encode '%' in a correct escape sequence (default: true)
    #------------------------------------------------------------------------------
    def self.encode(string, exclude = nil, keepEscaped = nil)
      result = ''

      if !exclude.is_a? String
        # encode(string, keepEscaped)
        keepEscaped = exclude
        exclude = DEFAULT_CHARACTERS
      end

      if keepEscaped == nil
        keepEscaped = true
      end

      cache = getEncodeCache(exclude)

      i = 0
      l = string.length
      while i < l
        code = string[i].ord

        if (keepEscaped && code == 0x25 && i + 2 < l) #  %
          if (/^[0-9a-f]{2}$/i =~ (string.slice((i + 1)...(i + 3))))
            result += string.slice(i...(i + 3))
            i += 3
            next
          end
        end

        if (code < 128)
          result += cache[code]
          i += 1
          next
        end

        if (code >= 0xD800 && code <= 0xDFFF)
          if (code >= 0xD800 && code <= 0xDBFF && i + 1 < l)
            nextCode = string[i + 1].ord
            if (nextCode >= 0xDC00 && nextCode <= 0xDFFF)
              result += CGI::escape(string[i] + string[i + 1])
              i += 2
              next
            end
          end
          result += '%EF%BF%BD'
          i += 1
          next
        end

        result += CGI::escape(string[i])
        i += 1
      end

      return result
    end
  end
end