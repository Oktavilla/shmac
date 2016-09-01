require "shmac/security"

module Shmac
  class AuthorizationHeader
    include Comparable
    class FormatError < StandardError; end

    AUTH_HEADER_PATTERN = /(.+) (.+):(.+)$/

    attr_reader :parts

    def self.generate organization:, access_key:, signature:
      new("%s %s:%s" % [organization, access_key, signature])
    end

    def initialize value
      @value = value
      self.parts = value
    end

    def == other
      return false unless other.is_a?(self.class)

      Security.secure_compare self.to_s, other.to_s
    end

    def to_s
      @value
    end

    def parts= value
      matches = AUTH_HEADER_PATTERN.match(value)
      unless matches
        raise FormatError.new("#{value} does not match the expected authorization signature")
      end

      @parts = matches
    end

    def organization
      parts[1]
    end

    def access_key_id
      parts[2]
    end

    def signature
      parts[3]
    end
  end
end
