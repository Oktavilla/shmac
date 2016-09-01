require "spec_helper"
require "json"

module Shmac
  RSpec.describe SignatureCalculator do
    describe "#string_to_sign" do
      it "creates a string of the method, Content-MD5, Content-Type, Date and path seperated by line feeds" do
        req = Request.new(
          path: "/the-resource",
          method: "POST",
          headers: {
            "Content-MD5": "some-md5-string",
            "Date": "Thu, 17 Nov 2005 18:49:58 GMT"
          },
          content_type: "application/json"
        )

        calculator = new_calculator(request: req)

        expected_string_to_sign = [
          "POST",
          "some-md5-string",
          "application/json",
          "Thu, 17 Nov 2005 18:49:58 GMT",
          "/the-resource"
        ].join("\n")

        expect(calculator.string_to_sign).to eq expected_string_to_sign.strip
      end

      it "skips the path if the api version does not support it" do
        req = Request.new(
          path: "/the-resource",
          method: "POST",
          headers: {
            "Content-MD5": "some-md5-string",
            "Date": "Thu, 17 Nov 2005 18:49:58 GMT"
          },
          content_type: "application/json"
        )

        calculator = SignatureCalculator.new(
          secret: "some-identifier",
          request: req,
          header_namespace: "x-uni",
          options: { skip_path: true }
        )

        expected_string_to_sign = [
          "POST",
          "some-md5-string",
          "application/json",
          "Thu, 17 Nov 2005 18:49:58 GMT"
        ].join("\n")

        expect(calculator.string_to_sign).to eq expected_string_to_sign.strip
      end

      it "uses an empty line if the Content-MD5 is missing" do
        req = Request.new(
          path: "/",
          method: "GET",
          headers: { "Date": "Thu, 17 Nov 2005 18:49:58 GMT" },
          content_type: "application/json"
        )

        calculator = new_calculator(request: req)

        expected_string_to_sign = [
          "GET",
          "",
          "application/json",
          "Thu, 17 Nov 2005 18:49:58 GMT",
          "/"
        ].join("\n")

        expect(calculator.string_to_sign).to eq expected_string_to_sign.strip
      end

      it "uses the x-content-md5 fallback if available" do
        req = Request.new(
          path: "/",
          method: "PUT",
          headers: {
            "Date": "Thu, 17 Nov 2005 18:49:58 GMT",
            "X-Content-MD5": "the md5"
          },
          content_type: "application/json"
        )

        calculator = new_calculator(request: req)

        expected_string_to_sign = [
          "PUT",
          "the md5",
          "application/json",
          "Thu, 17 Nov 2005 18:49:58 GMT",
          "/"
        ].join("\n")

        expect(calculator.string_to_sign).to eq expected_string_to_sign.strip
      end

      it "uses an empty line if the Content-Type is missing" do
        req = Request.new(
          path: "/",
          method: "GET",
          headers: { "Date": "Thu, 17 Nov 2005 18:49:58 GMT" }
        )

        calculator = new_calculator(request: req)

        expected_string_to_sign = [
          "GET",
          "",
          "",
          "Thu, 17 Nov 2005 18:49:58 GMT",
          "/"
        ].join("\n")

        expect(calculator.string_to_sign).to eq expected_string_to_sign.strip
      end

      describe "with platform specific headers" do
        it "adds all platform specific headers normalized and sorted by keys as lines after the date" do
          req = Request.new(
            path: "/the-resource",
            method: "POST",
            headers: {
              " X-Uni-Magic " => "\n abracadabra\n\n",
              "X-Uni-Affirmation" => "You go! ",
              "X-Other" => "some other value",
              "Date": "Mon, 01 Jan 1990 00:00:00 GMT"
            },
            content_type: "application/json"
          )

          expected_string_to_sign = [
            "POST",
            "",
            "application/json",
            "Mon, 01 Jan 1990 00:00:00 GMT",
            "x-uni-affirmation:You go!",
            "x-uni-magic:abracadabra",
            "/the-resource"
          ].join("\n")

          calculator = new_calculator(request: req)
          expect(calculator.string_to_sign).to eq expected_string_to_sign.strip
        end

        describe "special case date header" do
          # Best guess how to handle http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html#d0e37684
          it "prefers the value of a plattform specific date header over the normal date header" do
            req = Request.new(
              path: "/the-resource",
              method: "POST",
              headers: {
                "Date": "Sun, 07 Jan 1991 10:00:00 GMT",
                "X-Uni-Date" => "Mon, 01 Jan 1990 00:00:00 GMT"
              }
            )

            expected_string_to_sign = [
              "POST",
              "",
              "",
              "Mon, 01 Jan 1990 00:00:00 GMT",
              "x-uni-date:Mon, 01 Jan 1990 00:00:00 GMT",
              "/the-resource"
            ].join("\n")

            calculator = new_calculator(request: req)
            expect(calculator.string_to_sign).to eq expected_string_to_sign.strip
          end
        end
      end
    end

    describe "#signature" do
      it "creates a base 64 encoded HMAC signature from the secret key and string_to_sign" do
        req = Request.new(
          path: "/the-resource",
          method: "POST",
          headers: {
            "Date": "Sun, 07 Jan 1991 10:00:00 GMT",
            "X-Uni-Date" => "Mon, 01 Jan 1990 00:00:00 GMT"
          }
        )

        calculator = SignatureCalculator.new(secret: "some-identifier", request: req)

        digest = OpenSSL::Digest.new "sha1"
        hmac = OpenSSL::HMAC.digest digest, "some-identifier", calculator.string_to_sign
        expected_signature = Base64.strict_encode64 hmac

        expect(calculator.signature).to eq expected_signature
      end

      # Mainly exists so we can have a value that we can agree on =)
      it "returns an expected value" do
        req = Request.new(
          path: "/the-resource",
          method: "POST",
          headers: {
            " X-Uni-Magic " => "\n abracadabra\n\n",
            "X-Other" => "some other value",
            "X-Uni-Date" => "Thu, 17 Nov 2005 18:49:58 GMT",
            "Content-MD5" => Digest::MD5.base64digest(JSON.dump("FirstName" => "Jane" )),
            "Date": "Mon, 01 Jan 1990 00:00:00 GMT"
          },
          content_type: "application/json"
        )

        calculator = new_calculator(request: req)

        expect(calculator.signature).to eq "Bqi/7cJvBGbioNhEAfncYBl8rm4="
      end
    end

    describe "#to_s" do
      it "returns the signature" do
        req = Request.new(
          path: "/the-resource",
          method: "POST",
          headers: {
            " X-Uni-Magic " => "\n abracadabra\n\n",
            "X-Other" => "some other value",
            "X-Uni-Date" => "Thu, 17 Nov 2005 18:49:58 GMT",
            "Content-MD5" => Digest::MD5.base64digest(JSON.dump("FirstName" => "Jane")),
            "Date": "Mon, 01 Jan 1990 00:00:00 GMT"
          },
          content_type: "application/json"
        )

        calculator = new_calculator(request: req)

        expect(calculator.to_s).to eq calculator.signature
      end
    end

    it "supports amazons example from http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html#RESTAuthenticationExamples" do
      req = Request.new(
        path: "/johnsmith/photos/puppy.jpg",
        method: "PUT",
        headers: {
          "Date": "Tue, 27 Mar 2007 21:15:45 +0000"
        },
        body: "",
        content_type: "image/jpeg"
      )

      calc = SignatureCalculator.new(
        secret: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        request: req,
        header_namespace: "x-uni"
      )

      expected_canonicalized = [
        "PUT",
        "",
        "image/jpeg",
        "Tue, 27 Mar 2007 21:15:45 +0000",
        "/johnsmith/photos/puppy.jpg"
      ].join("\n")

      expect(calc.string_to_sign).to eq expected_canonicalized
      expect(calc.signature).to eq "MyyxeRY7whkBe+bq8fHCL/2kKUg="
    end

    def new_calculator request:
      SignatureCalculator.new(
        secret: "some-identifier",
        request: request,
        header_namespace: "x-uni"
      )
    end
  end
end
