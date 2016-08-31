module Shmac
  class NormalizedHttpHeaders
    def self.from_request_headers request_headers
      new(
        Hash[
          request_headers.to_h.find_all { |(k, _)|
            k.upcase.start_with?("HTTP_")
          }
        ]
      )
    end

    attr_reader :headers

    def initialize http_headers
      self.headers = http_headers
    end

    def to_h
      headers
    end

    def headers= http_headers
      @headers = http_headers.each_with_object({}) { |(k,v), memo|
        memo[normalize_key(k)] = Array(v).join(",")
      }
    end

    def normalize_key key
      key.to_s.downcase.tr("_", "-").gsub(/\Ahttp-/, "")
    end
  end
end
