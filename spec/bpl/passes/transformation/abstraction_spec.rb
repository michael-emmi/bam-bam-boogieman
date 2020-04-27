# typed: false
require "bpl/passes/transformation/abstraction.rb"

module Bpl
  describe Abstraction do

    it "can be run" do
      abstraction = Abstraction.new
      program = bpl_program <<-END
        axiom true;
      END

      expect { abstraction.run! program }.to_not raise_error
    end

    it "recognizes axiom abstractions" do
      abstraction = Abstraction.new(index: "count")

      positive = bpl_program <<-END
        axiom 1 == 2;
      END

      negative = bpl_program <<-END
        axiom true;
      END

      expect { abstraction.run! positive }.to_not raise_error
      expect { abstraction.run! negative }.to_not raise_error
      expect(positive.declarations.first.get_attribute(:count).first.value).to eq(1)
      expect(negative.declarations.first.get_attribute(:count).first.value).to eq(0)
    end


    it "recognizes assume abstractions" do
      pending "theres a bug in abstarction dependencies"

      abstraction = Abstraction.new(index: "count")

      positive = bpl_program <<-END
        procedure p() {
          assume false;
        }
      END

      negative = bpl_program <<-END
        procedure p() {
          assume true;
        }
      END

      expect { abstraction.run! positive }.to_not raise_error
      expect { abstraction.run! negative }.to_not raise_error
      expect(positive.declarations.first.get_attribute(:count).first.value).to eq(1)
      expect(negative.declarations.first.get_attribute(:count).first.value).to eq(0)
    end

  end
end
