require "shmac/normalized_http_headers"
require "shmac/security"

module Shmac
  class Request
    attr_reader :path, :method, :headers, :body, :content_type

    def initialize path:, method:, headers:, body: nil, content_type: nil
      @path = path
      @method = method
      self.headers = headers
      @body = body
      @content_type = content_type
    end

    # Prefer the value of a namespaced date key if present
    def date namespace = nil
      date_key = [namespace, "date"].compact.join("-").downcase

      headers.fetch(date_key) { headers["date"] }
    end

    def content_md5
      # Fallback to x-content-md5 for clients that have issues with standard headers
      headers.fetch("content-md5") { headers["x-content-md5"] }
    end

    def tampered_body?
      return false unless body
      return false if content_md5.to_s.strip.empty?

      !content_md5_matches_body?
    end

    def content_md5_matches_body?
      Security.secure_compare content_md5, Digest::MD5.base64digest(body)
    end

    def authorization
      # Test for x-authorization for clients that have issues with standard headers
      headers.fetch("x-authorization") { headers["authorization"] }
    end

    def headers= headers
      @headers = NormalizedHttpHeaders.new(headers).to_h
    end
  end
end
