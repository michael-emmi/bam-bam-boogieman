
module Bpl
  module AST

    class Program

      def verify(options = {})
        if options[:incremental]
          verify_incremental options
        else
          verify_one_shot options
        end
      end

      def verify_incremental(options = {})
        unroll_bound = options[:unroll] || Float::INFINITY
        delay_bound = options[:delays] || Float::INFINITY

        (0..Float::INFINITY).each do |i|
          break if (i > unroll_bound || i > delay_bound)

          Kernel::print "Verifying w/ #{i+1} unrolls and #{i} delays... "

          _, trace = vvvvv(options.merge(unroll: i+1, delays: i))
        
          break if File.read(trace).lines.last.
          match(/Boogie .* finished with (\d+) verified, (\d+) error/) do |m|
            if m[2].to_i > 0
              puts "Got a trace..."
              true
            else
              puts "all #{m[1]} entry points verified."
            end
          end
        end
      end

      def verify_one_shot(options = {})

        # puts "* Boogie: #{src}" unless @@quiet

        _, trace = vvvvv(options)
        
        File.read(trace).lines.last.
        match(/Boogie .* finished with (\d+) verified, (\d+) error/) do |m|
          if m[2].to_i > 0
            puts "Got a trace..."
          else
            puts "All #{m[1]} entry points verified."
          end
        end


        # output = `#{cmd}`

        # res = output.match /(\d+) verified, (\d+) errors?/ do |m| m[2].to_i > 0 end
        # warn "unexpected Boogie result: #{output}" if res.nil?
  
        # res = nil if output.match(/ \d+ time outs?/)  
    
        # time = output.match /Boogie finished in ([0-9.]+)s./ do |m| m[1].to_f end
        # warn "unknown Boogie time" unless time
  
        # puts "#{res.nil? ? "TO" : res} / #{time} / #{args.reject{|k,_| k =~ /limit/}}"
        # return res
        
        # cleanup = []
        # if not $?.success? then
        #   err "problem with Boogie: #{output}"
        # else
        #   if @graph && output =~ /[1-9]\d* errors?/ then
        #     puts "Rendering error trace.." unless @quiet
        #     File.open("#{src}.trace",'w'){|f| f.write(output) }
        #     showtrace "#{src}.trace"
        #   else
        #     if @@quiet then
        #       puts output.lines.select{|l| l =~ /[0-9]* verified/}[0]
        #     else
        #       puts output.lines.reject{|l| l.strip.empty?} * ""
        #     end
        #   end
        # end 
        # File.delete( *cleanup ) unless @keep
        # puts "Boogie finished in #{Time.now - t}s." unless @@quiet
      end

      def vvvvv(options = {})
        boogie_opts = []

        orig = source_file || "a.bpl"
        src = File.basename(orig).chomp(File.extname(orig)) + ".c2s.bpl"
        model = src.chomp('.bpl') + '.model'
        trace = src.chomp('.bpl') + '.trace'

        warn "without specifying an unroll bound, Boogie may not terminate" \
          unless options[:unroll]

        case options[:verifier]
        when :boogie_fi, nil
          boogie_opts << "/loopUnroll:#{options[:unroll]}" if options[:unroll]

        when :boogie_si
          boogie_opts << "/stratifiedInline:2"
          boogie_opts << "/extractLoops"
          boogie_opts << "/recursionBound:#{options[:unroll]}" if options[:unroll]
          boogie_opts << "/weakArrayTheory"
          boogie_opts << "/siVerbose:1" if $verbose

        else
          err "invalid back-end: #{options[:verifier]}"
        end

        boogie_opts << "/errorLimit:1"
        boogie_opts << "/errorTrace:2"
        boogie_opts << "/printModel:2"
        boogie_opts << "/printModelToFile:#{model}"
        boogie_opts << "/removeEmptyBlocks:0" # XXX
        boogie_opts << "/coalesceBlocks:0"    # XXX

        if @declarations.any?{|d| d.is_a?(ConstantDeclaration) && d.names.include?('#DELAYS')}
          @declarations.push bpl("axiom #ROUNDS == #{options[:rounds]};")
          @declarations.push bpl("axiom #DELAYS == #{options[:delays]};")
        end
        File.write(src,self)
        if @declarations.any?{|d| d.is_a?(ConstantDeclaration) && d.names.include?('#DELAYS')}
          @declarations.pop
          @declarations.pop
        end

        cmd = "#{boogie} #{src} #{boogie_opts * " "} 1> #{trace}"
        puts cmd.bold if $verbose
        t = Time.now

        system cmd

        return model, trace
      end

    end

  end
end
