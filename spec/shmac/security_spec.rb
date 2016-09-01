require "spec_helper"

module Shmac
  RSpec.describe Security do
    describe ".secure_compare" do
      it "is true for equal strings" do
        expect(
          Security.secure_compare("well well well…", "well well well…")
        ).to be true
      end

      it "is false for non equal strings" do
        expect(
          Security.secure_compare("well well well…", "well well nope…")
        ).to be false
      end
    end
  end
end
