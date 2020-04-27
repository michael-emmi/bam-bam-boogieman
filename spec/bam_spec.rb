# typed: false
require "bam"

describe BAM do
  it "has a version number" do
    expect(BAM::VERSION).not_to be nil
  end

  it "should run without errors" do
    expect { BAM::Main.new.main [] }.to_not raise_error
  end
end
