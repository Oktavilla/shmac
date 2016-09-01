require "openssl"
require "base64"

module Shmac
  class SignatureCalculator
    attr_reader :secret, :request, :header_namespace, :options

    def initialize secret:, request:, header_namespace: nil, options: {}
      @secret = secret
      @request = request
      @header_namespace = header_namespace.downcase if header_namespace
      @options = options
    end

    def to_s
      signature
    end

    def signature
      digest = OpenSSL::Digest.new "sha1"
      hmac = OpenSSL::HMAC.digest digest, secret, string_to_sign
      Base64.strict_encode64 hmac
    end

    def string_to_sign
      parts = [
        request.method,
        request.content_md5,
        request.content_type,
        request.date(self.header_namespace)
      ]

      platform_headers = canonicalized_platform_headers.to_s.strip
      parts << platform_headers unless platform_headers.empty?

      # The path is expected by spec but the DPO sends the same message (including headers) to several endpoints
      # We introduce an api version so we do not lose messages
      parts << request.path unless options[:skip_path]

      parts.join("\n")
    end

    def canonicalized_platform_headers
      return unless self.header_namespace

      normalize_key = -> (key) { key.to_s.downcase.strip }
      normalize_value = -> (value) { value.to_s.strip }
      canonicalized_header_row = -> (k,v) {
        "%s:%s" % [normalize_key.(k), normalize_value.(v)]
      }
      matches_namespace = ->(value) { value.start_with?(header_namespace) }

      self.request.headers
        .map(&canonicalized_header_row)
        .find_all(&matches_namespace)
        .sort
        .join("\n")
    end
  end
end
