require "spec_helper"

module Shmac
  module RequestAdapters
    RSpec.describe Rails do
      it "converts a rails request to an Shmac::Request" do
        rails_request = double(
          "ActionDispatch::TestRequest",
          fullpath: "/some-path",
          request_method: "post",
          headers: {
            "HTTP_DATE" => Time.utc(1990).httpdate,
            "HTTP_X_UNI_MAGIC" => "abracadabra",
            "HTTP_X_OTHER" => "some other value"
          },
          raw_post: "the body",
          content_type: "application/json"
        )

        request = Rails.call(rails_request)

        expect(request).to be_a Shmac::Request
        expect(request.path).to eq "/some-path"
        expect(request.method).to eq "POST"
        expect(request.headers).to eq({
          "date" => Time.utc(1990).httpdate,
          "x-uni-magic" => "abracadabra",
          "x-other" => "some other value"
        })
        expect(request.body).to eq "the body"
        expect(request.content_type).to eq "application/json"
      end
    end

    RSpec.describe NetHttp do
      it "converts a Net::Http request to an Shmac::Request" do
        uri = URI.parse("https://example.com/some-path")
        net_http_request = Net::HTTP::Post.new(uri, {
          "Date" => Time.utc(1990).httpdate,
          "X-Uni-Magic" => "abracadabra",
          "X-Other" => "some other value",
          "Content-Type" => "application/json"
        })
        net_http_request.body = "the body"

        request = NetHttp.call(net_http_request)

        expect(request).to be_a Shmac::Request
        expect(request.path).to eq "/some-path"
        expect(request.method).to eq "POST"
        expect(request.headers["date"]).to eq Time.utc(1990).httpdate
        expect(request.headers["x-uni-magic"]).to eq "abracadabra"
        expect(request.headers["x-other"]).to eq "some other value"
        expect(request.body).to eq "the body"
        expect(request.content_type).to eq "application/json"
      end
    end
  end
end
