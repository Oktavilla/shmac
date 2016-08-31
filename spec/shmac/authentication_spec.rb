require "spec_helper"

module Shmac
  RSpec.describe Authentication do
    let :request_body do
      "the actual http request body"
    end

    let :request do
      Request.new(
        path: "/some-path",
        method: "POST",
        headers: {
          "X-Content-MD5" => Digest::MD5.base64digest(request_body),
          "X-Uni-Date" => Time.utc(1990).httpdate
        },
        body: request_body,
        content_type: "application/json"
      )
    end

    it "uses the SignatureCalculator to generate a signature from the request" do
      calculator = SignatureCalculator.new(
        secret: "password",
        request: request,
        header_namespace: "x-uni"
      )

      expect(Authentication.new("password", request).signature).to eq calculator.to_s
    end

    it "is comparable via signature" do
      expect(Authentication.new("password", request)).to eq Authentication.new("password", request)

      expect(Authentication.new("password", request)).to_not eq Authentication.new("other-secret", request)
    end

    describe "#authentic?" do
      it "is false for an signature generated with an invalid secret" do
        allow(request).to receive(:authorization).and_return Shmac::AuthorizationHeader.generate(
          organization: "Org",
          access_key: "test-client",
          signature: Authentication.new("wrong-secret", request).signature
        ).to_s

        expect(Authentication.new("password", request).authentic?).to be false
      end

      it "is false for an signature with a bogus signature" do
        allow(request).to receive(:authorization).and_return Shmac::AuthorizationHeader.generate(
          organization: "Org",
          access_key: "test-client",
          signature: "some-random-string"
        ).to_s

        expect(Authentication.new("password", request).authentic?).to be false
      end

      it "is false for an empty signature" do
        allow(request).to receive(:authorization).and_return nil

        expect(Authentication.new("password", request).authentic?).to be false
      end

      it "is true for a correctly signed request" do
        allow(request).to receive(:authorization).and_return Shmac::AuthorizationHeader.generate(
          organization: "Org",
          access_key: "test-client",
          signature: Authentication.new("password", request).signature
        ).to_s

        expect(Authentication.new("password", request).authentic?).to be true
      end
    end
  end

end
