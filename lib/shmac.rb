require "shmac/version"
require "shmac/authentication"
require "shmac/request_adapters"

module Shmac
  def self.rails secret, request, namespace: nil, options: {}
    authentication(secret, request, namespace: namespace, request_adapter: RequestAdapters::Rails, options: options)
  end

  def self.net_http secret, request, namespace: nil, options: {}
    authentication(secret, request, namespace: namespace, request_adapter: RequestAdapters::NetHttp, options: options)
  end

  def self.authentication secret, request, namespace: nil, request_adapter: nil, options: {}
    Authentication.new(
      secret,
      request,
      header_namespace: namespace,
      request_adapter: request_adapter,
      options: options
    )
  end
end
