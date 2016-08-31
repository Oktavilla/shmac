require "shmac/version"
require "shmac/authentication"
require "shmac/request_adapters"

module Shmac
  def self.rails secret, request, namespace: nil
    authentication(secret, request, namespace: namespace, request_adapter: RequestAdapters::Rails)
  end

  def self.net_http secret, request, namespace: nil
    authentication(secret, request, namespace: namespace, request_adapter: RequestAdapters::NetHttp)
  end

  def self.authentication secret, request, namespace: nil, request_adapter: nil
    Authentication.new(
      secret,
      request,
      header_namespace: namespace,
      request_adapter: request_adapter
    )
  end
end
