require "shmac/authentication"
require "shmac/request"
require "shmac/normalized_http_headers"

module Shmac
  class Rails
    attr_reader :secret, :request, :header_namespace

    def initialize secret, rails_request, header_namespace: "x-uni"
      @secret = secret
      @request = rails_request
      @header_namespace = header_namespace
    end

    def authentic?
      authentication.authentic?
    end

    def signature
      authentication.signature
    end

    def authentication
      @authentication ||= Authentication.new(
        secret,
        request_from_rails_request(request),
        header_namespace: header_namespace
      )
    end

    private

    def request_from_rails_request rails_request
      Request.new(
        path: rails_request.fullpath,
        method: rails_request.request_method.to_s.upcase,
        headers: Shmac::NormalizedHttpHeaders.from_request_headers(rails_request.headers).to_h,
        body: rails_request.raw_post,
        content_type: rails_request.content_type
      )
    end
  end
end
