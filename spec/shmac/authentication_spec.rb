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
          "Content-MD5" => Digest::MD5.base64digest(request_body),
          "Date" => Time.utc(1990).httpdate
        },
        body: request_body,
        content_type: "application/json"
      )
    end

    describe "#options" do
      it "has sane defaults" do
        expect(
          Authentication.new("test", request).options
        ).to eq(skip_path: false)
      end

      it "can be set through the constructor" do
        expect(
          Authentication.new(
            "test",
            request,
            options: { skip_path: true }
          ).options
        ).to eq(skip_path: true)
      end

      it "does not allow unknown options" do
        expect{
          Authentication.new(
            "test",
            request,
            options: { lol: false }
          )
        }.to raise_error(ArgumentError)
      end
    end

    it "uses the SignatureCalculator to generate a signature from the request" do
      calculator = SignatureCalculator.new(
        secret: "password",
        request: request,
        header_namespace: "x-uni"
      )

      expect(Authentication.new("password", request, header_namespace: "x-uni").signature).to eq calculator.to_s
    end

    it "passes the skip_path option signature calculator" do
      calculator = SignatureCalculator.new(
        secret: "password",
        request: request,
        options: { skip_path: true }
      )

      expect(
        Authentication.new(
          "password",
          request,
          options: { skip_path: true }
        ).signature
      ).to eq calculator.to_s
    end

    it "takes a request_adapter that can alter the given request" do
      fake_request = Request.new(
        path: "/fake-path",
        method: "PUT",
        headers: {
          "Content-MD5" => "lol",
          "Date" => Time.utc(1990).httpdate
        },
        body: "other",
        content_type: "application/banana"
      )
      calculator = SignatureCalculator.new(
        secret: "password",
        request: fake_request,
        header_namespace: "x-uni"
      )

      adapter = ->(_) { fake_request }

      expect(
        Authentication.new("password", request, request_adapter: adapter).signature
      ).to eq calculator.to_s
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

      it "is false if the body has been tampered with" do
        request = Request.new(
          path: "/some-path",
          method: "POST",
          headers: {},
          content_type: "application/json"
        )

        allow(request).to receive(:authorization).and_return Shmac::AuthorizationHeader.generate(
          organization: "Org",
          access_key: "test-client",
          signature: Authentication.new("password", request).signature
        ).to_s

        expect(
          Authentication.new("password", request).authentic?
        ).to be true

        allow(request).to receive(:tampered_body?) { true }

        expect(
          Authentication.new("password", request).authentic?
        ).to be false
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
