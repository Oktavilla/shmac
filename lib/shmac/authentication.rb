require "shmac/signature_calculator"
require "shmac/authorization_header"

module Shmac
  class Authentication
    include Comparable

    attr_reader :secret, :request, :header_namespace

    def initialize secret, request, header_namespace: "x-uni"
      @secret = secret
      @request = request
      @header_namespace = header_namespace
    end

    def == other
      other.is_a?(self.class) && self.signature == other.signature
    end

    def signature
      SignatureCalculator.new(
        secret: self.secret,
        request: self.request,
        header_namespace: self.header_namespace
      ).to_s
    end

    def authentic?
      return false if request.authorization.to_s.strip.empty?

      AuthorizationHeader.new(request.authorization).signature == self.signature
    end
  end
end
