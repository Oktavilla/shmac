require "spec_helper"

module Shmac
  RSpec.describe Request do
    it "normalizes all header keys" do
      req = Request.new(path: "/", method: "POST", headers: {
        "Some-Header" => "value"
      })

      expect(req.headers.fetch("some-header")).to eq "value"
    end

    describe "#date" do
      it "returns the standard date header" do
        req = Request.new(path: "/", method: "POST", headers: {
          "Date" => "Tue, 27 Mar 2007 21:15:45 +0000"
        })

        expect(req.date).to eq "Tue, 27 Mar 2007 21:15:45 +0000"
      end

      it "prefers the namespaced date key" do
        req = Request.new(path: "/", method: "POST", headers: {
          "Date" => "Tue, 27 Mar 2007 21:15:45 +0000",
          "Namespaced-Date" => "Wed, 28 Mar 2007 21:15:45 +0000"
        })

        expect(req.date("namespaced")).to eq "Wed, 28 Mar 2007 21:15:45 +0000"
      end
    end

    describe "#content_md5" do
      it "returns the Content-MD5 header" do
        req = Request.new(path: "/", method: "POST", headers: {
          "Content-MD5" => "some-hash"
        })

        expect(req.content_md5).to eq "some-hash"
      end

      it "falls back to X-Content-MD5" do
        req = Request.new(path: "/", method: "POST", headers: {
          "X-Content-MD5" => "some-hash"
        })

        expect(req.content_md5).to eq "some-hash"
      end
    end

    describe "#authorization" do
      it "returns the X-Authorization header" do
        req = Request.new(path: "/", method: "POST", headers: {
          "X-Authorization" => "some-auth"
        })

        expect(req.authorization).to eq "some-auth"
      end

      it "falls back to Authorization" do
        req = Request.new(path: "/", method: "POST", headers: {
          "Authorization" => "some-auth"
        })

        expect(req.authorization).to eq "some-auth"
      end
    end
  end

end
