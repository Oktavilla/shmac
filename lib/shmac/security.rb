module Shmac
  module Security
    # Constant time comparison of strings
    # Borrowed from ActiveSupport::SecurityUtils
    def self.secure_compare a, b
      return false if a.empty? || b.empty?
      return false unless a.bytesize == b.bytesize

      l = a.unpack "C#{a.bytesize}"

      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res == 0
    end
  end
end
