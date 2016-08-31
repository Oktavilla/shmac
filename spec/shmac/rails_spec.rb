require "spec_helper"
require "json"

module Shmac
  RSpec.describe Rails do
    let :payload_body do
      JSON.dump("FirstName" => "Jane")
    end

    let :rails_request do
      double(
        "ActionDispatch::TestRequest",
        fullpath: "/some-path",
        request_method: "post",
        headers: {
          "HTTP_X_UNI_DATE" => Time.utc(1990).httpdate,
          "HTTP_X_UNI_MAGIC" => "\nabracadabra\n\n",
          "HTTP_X_OTHER" => "some other value"
        },
        raw_post: payload_body,
        content_type: "application/json"
      )
    end

    let :rails do
      Rails.new "password", rails_request
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

    it "maps an rails request to internal format and passes on to an Authentication instance" do
      expect(rails.authentication).to eq authentication
    end

    it "delegates signature to the authentication" do
      expect(rails.signature).to eq rails.authentication.signature
    end

    it "delegates authentic? to authentication" do
      allow(rails.authentication).to receive(:authentic?) { "yus" }

      expect(rails.authentic?).to eq "yus"
    end
  end
end
