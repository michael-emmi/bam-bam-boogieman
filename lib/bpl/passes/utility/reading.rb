# typed: true
module Bpl
  class Reading < Pass

    option :file
    switch "-i", "--input FILENAME" do |y, f|
      y.yield :file, f
    end

    def run!
      added(BoogieLanguage.new.parse(File.read(file)))
    end

  end
end
