# Copyright Joyent, Inc. and other Node contributors.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the
# following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.

#
# Changes from joyent/node:
#
# 1. No leading slash in paths,
#    e.g. in `url.parse('http://foo?bar')` pathname is ``, not `/`
#
# 2. Backslashes are not replaced with slashes,
#    so `http:\\example.org\` is treated like a relative path
#
# 3. Trailing colon is treated like a part of the path,
#    i.e. in `http://example.org:foo` pathname is `:foo`
#
# 4. Nothing is URL-encoded in the resulting object,
#    (in joyent/node some chars in auth and paths are encoded)
#
# 5. `url.parse()` does not have `parseQueryString` argument
#
# 6. Removed extraneous result properties: `host`, `path`, `query`, etc.,
#    which can be constructed using other parts of the url.
#

module MDUrl
  class Url

    attr_accessor   :protocol, :slashes, :hostname, :pathname, :auth, :port, :search, :hash
    
    # Reference: RFC 3986, RFC 1808, RFC 2396

    # define these here so at least they only have to be
    # compiled once on the first module load.
    PROTOCOL_PATTERN  = /^([a-z0-9.+-]+:)/i
    PORT_PATTERN      = /:[0-9]*$/

    # Special case for a simple path URL
    SIMPLE_PATH_PATTERN = /^(\/\/?(?!\/)[^\?\s]*)(\?[^\s]*)?$/

    # RFC 2396: characters reserved for delimiting URLs.
    # We actually just auto-escape these.
    DELIMS = [ '<', '>', '"', '`', ' ', '\r', '\n', '\t' ]

    # RFC 2396: characters not allowed for various reasons.
    UNWISE = [ '{', '}', '|', '\\', '^', '`' ].concat(DELIMS)

    # Allowed by RFCs, but cause of XSS attacks.  Always escape these.
    AUTO_ESCAPE = [ '\'' ].concat(UNWISE)
    # Characters that are never ever allowed in a hostname.
    # Note that any invalid chars are also handled, but these
    # are the ones that are *expected* to be seen, so we fast-path
    # them.
    NON_HOST_CHARS = [ '%', '/', '?', ';', '#' ].concat(AUTO_ESCAPE)
    HOST_ENDING_CHARS = [ '/', '?', '#' ]
    HOSTNAME_MAX_LEN = 255
    HOSTNAME_PART_PATTERN = /^[+a-z0-9A-Z_-]{0,63}$/
    HOSTNAME_PART_START = /^([+a-z0-9A-Z_-]{0,63})(.*)$/
    # protocols that can allow "unsafe" and "unwise" chars.
    # protocols that never have a hostname.
    HOSTLESS_PROTOCOL = {
      'javascript' => true,
      'javascript:' => true
    }
    # protocols that always contain a # bit.
    SLASHED_PROTOCOL = {
      'http' => true,
      'https' => true,
      'ftp' => true,
      'gopher' => true,
      'file' => true,
      'http:' => true,
      'https:' => true,
      'ftp:' => true,
      'gopher:' => true,
      'file:' => true
    }

    #------------------------------------------------------------------------------
    def self.urlParse(url, slashesDenoteHost = false)
      return url if (url && url.is_a?(Url))

      u = Url.new
      u.parse(url, slashesDenoteHost)
      return u
    end

    #------------------------------------------------------------------------------
    def parse(url, slashesDenoteHost = false)
      rest = url

      # trim before proceeding.
      # This is to support parse stuff like "  http://foo.com  \n"
      rest = rest.strip

      if (!slashesDenoteHost && url.split('#').length == 1)
        # Try fast path regexp
        simplePath = SIMPLE_PATH_PATTERN.match(rest)
        if (simplePath)
          @pathname = simplePath[1]
          if (simplePath[2])
            @search = simplePath[2]
          end
          return self
        end
      end

      proto = PROTOCOL_PATTERN.match(rest)
      if (proto)
        proto      = proto[0]
        lowerProto = proto.downcase
        @protocol  = proto
        rest       = rest[proto.length..-1]
      end

      # figure out if it's got a host
      # user@server is *always* interpreted as a hostname, and url
      # resolution will treat //foo/bar as host=foo,path=bar because that's
      # how the browser resolves relative URLs.
      if (slashesDenoteHost || proto || rest.match(/^\/\/[^@\/]+@[^@\/]+/))
        slashes = rest[0...2] == '//'
        if (slashes && !(proto && HOSTLESS_PROTOCOL[proto]))
          rest = rest[2..-1]
          @slashes = true
        end
      end

      if (!HOSTLESS_PROTOCOL[proto] &&
          (slashes || (proto && !SLASHED_PROTOCOL[proto])))

        # there's a hostname.
        # the first instance of /, ?, ;, or # ends the host.
        #
        # If there is an @ in the hostname, then non-host chars *are* allowed
        # to the left of the last @ sign, unless some host-ending character
        # comes *before* the @-sign.
        # URLs are obnoxious.
        #
        # ex:
        # http://a@b@c/ => user:a@b host:c
        # http://a@b?@c => user:a host:c path:/?@c

        # v0.12 TODO(isaacs): This is not quite how Chrome does things.
        # Review our test case against browsers more comprehensively.

        # find the first instance of any HOST_ENDING_CHARS
        hostEnd = -1
        (0...HOST_ENDING_CHARS.length).each do |i|
          hec = rest.index(HOST_ENDING_CHARS[i])
          if (hec != nil && (hostEnd == -1 || hec < hostEnd))
            hostEnd = hec
          end
        end

        # at this point, either we have an explicit point where the
        # auth portion cannot go past, or the last @ char is the decider.
        if (hostEnd == -1)
          # atSign can be anywhere.
          atSign = rest.rindex('@')
        else
          # atSign must be in auth portion.
          # http://a@b/c@d => host:b auth:a path:/c@d
          # atSign = rest.lastIndexOf('@', hostEnd);
          atSign = rest[0..hostEnd].rindex('@')
        end

        # Now we have a portion which is definitely the auth.
        # Pull that off.
        if (atSign != nil)
          auth = rest.slice(0...atSign)
          rest = rest.slice((atSign + 1)..-1)
          @auth = auth
        end

        # the host is the remaining to the left of the first non-host char
        hostEnd = -1
        (0...NON_HOST_CHARS.length).each do |i|
          hec = rest.index(NON_HOST_CHARS[i])
          if (hec != nil && (hostEnd == -1 || hec < hostEnd))
            hostEnd = hec
          end
        end
        # if we still have not hit it, then the entire thing is a host.
        if (hostEnd === -1)
          hostEnd = rest.length
        end

        hostEnd -= 1 if (rest[hostEnd - 1] == ':')
        host = rest.slice(0...hostEnd)
        rest = rest.slice(hostEnd..-1)

        # pull out port.
        self.parseHost(host)

        # we've indicated that there is a hostname,
        # so even if it's empty, it has to be present.
        @hostname = @hostname || ''

        # if hostname begins with [ and ends with ]
        # assume that it's an IPv6 address.
        ipv6Hostname = @hostname[0] == '[' &&
            @hostname[@hostname.length - 1] == ']'

        # validate a little.
        if (!ipv6Hostname)
          hostparts = @hostname.split(/\./)
          (0...hostparts.length).each do |i|
            part = hostparts[i]
            next if (!part)
            if (!part.match(HOSTNAME_PART_PATTERN))
              newpart = ''
              (0...part.length).each do |j|
                if (part[j].ord > 127)
                  # we replace non-ASCII char with a temporary placeholder
                  # we need this to make sure size of hostname is not
                  # broken by replacing non-ASCII by nothing
                  newpart += 'x'
                else
                  newpart += part[j]
                end
              end
              # we test again with ASCII char only
              if (!newpart.match(HOSTNAME_PART_PATTERN))
                validParts = hostparts.slice(0...i)
                notHost = hostparts.slice((i + 1)..-1)
                bit = part.match(HOSTNAME_PART_START)
                if (bit)
                  validParts.push(bit[1])
                  notHost.unshift(bit[2])
                end
                if (notHost.length)
                  rest = notHost.join('.') + rest
                end
                @hostname = validParts.join('.')
                break
              end
            end
          end
        end

        if (@hostname.length > HOSTNAME_MAX_LEN)
          @hostname = ''
        end

        # strip [ and ] from the hostname
        # the host field still retains them, though
        if (ipv6Hostname)
          @hostname = @hostname[1, @hostname.length - 2]
        end
      end

      # chop off from the tail first.
      hash = rest.index('#')
      if (hash != nil)
        # got a fragment string.
        @hash = rest.slice(hash..-1)
        rest  = rest.slice(0...hash)
      end
      qm = rest.index('?')
      if (qm != nil)
        @search = rest.slice(qm..-1)
        rest    = rest.slice(0...qm)
      end
      @pathname = rest if !rest.nil? && rest != ''
      if (SLASHED_PROTOCOL[lowerProto] &&
          @hostname && !@pathname)
        @pathname = ''
      end

      return self
    end

    #------------------------------------------------------------------------------
    def parseHost(host)
      port = PORT_PATTERN.match(host)
      if (port)
        port = port[0]
        if (port != ':')
          @port = port.slice(1..-1)
        end
        host = host[0, host.length - port.length]
      end
      @hostname = host if (host)
    end

  end
end