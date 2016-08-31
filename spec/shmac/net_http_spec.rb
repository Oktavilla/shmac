require "spec_helper"
require "json"

module Shmac
  RSpec.describe NetHttp do
    let :payload_body do
      JSON.dump("FirstName" => "Jane")
    end

    let :net_http_request do
      uri = URI.parse("https://example.com/some-path")
      req = Net::HTTP::Post.new(uri)
      req.body = payload_body


      req["X-Uni-Date"] = Time.utc(1990).httpdate
      req["X-Uni-Magic"] = "\nabracadabra\n\n"
      req["X-Other"] = "some other value"
      req["Content-Type"] = "application/json"
      req["RAW_POST_DATA"] = payload_body

      req
    end

    let :net_http do
      NetHttp.new "password", net_http_request
    end

    let :authentication do
      Authentication.new(
        "password",
        Request.new(
          method: "POST",
          headers: {
            "X-Uni-Magic" => "\nabracadabra\n\n",
            "X-Other" => "some other value",
            "X-Uni-Date" => Time.utc(1990).httpdate
          },
          body: payload_body,
          content_type: "application/json",
          path: "/some-path"
        ),
        header_namespace: "x-uni"
      )
    end

    it "maps an net http request to internal format and passes on to an Authentication instance" do
      expect(net_http.authentication).to eq authentication
    end

    it "delegates signature to the authentication" do
      expect(net_http.signature).to eq net_http.authentication.signature
    end

    it "delegates authentic? to authentication" do
      allow(net_http.authentication).to receive(:authentic?) { "yus" }

      expect(net_http.authentic?).to eq "yus"
    end
  end
end
