require "spec_helper"

module Shmac
  RSpec.describe AuthorizationHeader do
    let :header do
      AuthorizationHeader.new "UNICEF access-key:signature"
    end

    specify ".generate" do
      expect(
        AuthorizationHeader.generate(organization: "UNICEF", access_key: "some-key", signature: "123")
      ).to eq(AuthorizationHeader.new("UNICEF some-key:123"))
    end

    it "has an organization" do
      expect(header.organization).to eq "UNICEF"
    end

    it "has an access key" do
      expect(header.access_key_id).to eq "access-key"
    end

    it "has a signature" do
      expect(header.signature).to eq "signature"
    end

    it "raises an exeption if the header is malformed" do
      expect{
        AuthorizationHeader.new("broken")
      }.to raise_error(AuthorizationHeader::FormatError)
    end
  end
end
