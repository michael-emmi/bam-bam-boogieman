module BAM

  def self.process_source_file(src)
    case File.extname src
    when '.c', '.o', '.bc', '.ll'
      orig = src
      $temp << src = File.basename(orig).chomp(File.extname(orig)) + ".bpl"
      cmd = "#{smack} #{orig} -o #{src}"
      puts cmd.bold if $verbose
      abort "Failed to process LLVM bitcode" unless system cmd

    when '.bpl'

    else
      abort "Expecting Boogie, LLVM bitcode, or C source file."
    end
    src
  end
end
