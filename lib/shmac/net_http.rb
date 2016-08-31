require "shmac/authentication"
require "shmac/request"
require "shmac/normalized_http_headers"

module Shmac
  class NetHttp
    attr_reader :secret, :request, :header_namespace

    def initialize secret, request, header_namespace: "x-uni"
      @secret = secret
      @request = request
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
        request_from_net_http_request(request),
        header_namespace: header_namespace
      )
    end

    private

    def request_from_net_http_request net_http_request
      Request.new(
        path: net_http_request.uri.path,
        method: net_http_request.method.to_s.upcase,
        headers: NormalizedHttpHeaders.new(net_http_request.to_hash).to_h,
        body: net_http_request.body,
        content_type: net_http_request.content_type
      )
    end
  end
end
