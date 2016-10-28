require "shmac/signature_calculator"
require "shmac/authorization_header"
require "shmac/security"

module Shmac
  class Authentication
    include Comparable

    attr_reader :secret, :header_namespace, :options

    def self.generate_authorization_header request, secret:, access_key:, organization:, header_namespace: nil
      AuthorizationHeader.generate(
        organization: organization,
        access_key: access_key,
        signature: self.generate_signature(request, secret: secret, header_namespace: header_namespace)
      ).to_s
    end

    def self.generate_signature request, secret:, header_namespace: nil
      new(secret, request, header_namespace: header_namespace).signature
    end

    def initialize secret, request, header_namespace: nil, request_adapter: nil, options: {}
      @secret = secret
      @request = request
      @request_adapter = request_adapter
      @header_namespace = header_namespace
      self.options = options
    end

    def == other
      return false unless other.is_a?(self.class)

      Security.secure_compare self.signature, other.signature
    end

    def signature
      SignatureCalculator.new(
        secret: self.secret,
        request: self.request,
        header_namespace: self.header_namespace,
        options: { skip_path: self.options[:skip_path] }
      ).to_s
    end

    def authentic?
      return false if request.authorization.to_s.strip.empty?
      return false if request.tampered_body?

      given_signature = AuthorizationHeader.new(request.authorization).signature

      Security.secure_compare given_signature, self.signature
    end

    def request
      request_adapter.call @request
    end

    def request_adapter
      @request_adapter ||= ->(r) { r }
    end

    private

    def options= opts = {}
      unknown_keys = opts.keys - default_options.keys
      raise ArgumentError.new("Unknown options: #{unknown_keys.join(", ")}") if unknown_keys.any?

      @options = default_options.merge(opts)
    end

    def default_options
      { skip_path: false }
    end
  end
end
