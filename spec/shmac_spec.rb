require "spec_helper"

RSpec.describe Shmac do
  it "has a version number" do
    expect(Shmac::VERSION).not_to be nil
  end

  describe ".authentication" do
    it "returns an instance of Authentication" do
      request = Shmac::Request.new(path: "/", method: "get", headers: {})
      fake_adapater = ->(r) { r }

      expect(
        Shmac.authentication("password", request, namespace: "x-org-name", request_adapter: fake_adapater)
      ).to eq(Shmac::Authentication.new("password", request, header_namespace: "x-org-name", request_adapter: fake_adapater))
    end
  end

  describe ".rails" do
    it "returns an authentication with the Rails adapter" do
      request = double("ActionDispatch::Request", fullpath: "/", request_method: "post", raw_post: "", content_type: "text/html", headers: {})

      expect(
        Shmac.rails("password", request, namespace: "x-org-name")
      ).to eq(Shmac::Authentication.new("password", request, header_namespace: "x-org-name", request_adapter: Shmac::RequestAdapters::Rails))
    end
  end

  describe ".net_http" do
    it "returns an authentication with the NetHttp adapter" do
      request = double("Net::Http::Post", method: "post", body: "", content_type: "text/html", headers: {}, uri: URI("https://example.com"), to_hash: {})

      expect(
        Shmac.net_http("password", request, namespace: "x-org-name")
      ).to eq(Shmac::Authentication.new("password", request, header_namespace: "x-org-name", request_adapter: Shmac::RequestAdapters::NetHttp))
    end
  end
end
