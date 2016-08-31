require "shmac/request"
require "shmac/normalized_http_headers"

module Shmac
  module RequestAdapters
    Rails = ->(rails_request) {
      Request.new(
        path: rails_request.fullpath,
        method: rails_request.request_method.to_s.upcase,
        headers: Shmac::NormalizedHttpHeaders.from_request_headers(rails_request.headers).to_h,
        body: rails_request.raw_post,
        content_type: rails_request.content_type
      )
    }

    NetHttp = ->(net_http_request) {
      Request.new(
        path: net_http_request.uri.path,
        method: net_http_request.method.to_s.upcase,
        headers: NormalizedHttpHeaders.new(net_http_request.to_hash).to_h,
        body: net_http_request.body,
        content_type: net_http_request.content_type
      )
    }
  end
end
