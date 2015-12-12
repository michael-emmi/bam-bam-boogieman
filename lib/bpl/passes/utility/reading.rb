module Bpl
  class Reading < Pass

    flag "-i", "--input FILENAME" do |f|
      option :file, f
    end

    no_cache

    def run!
      added(BoogieLanguage.new.parse(File.read(file)))
    end

  end
end
