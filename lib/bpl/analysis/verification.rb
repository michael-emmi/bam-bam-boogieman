
module Bpl
  module AST

    class Program

      def verify(options = {})
        if options[:incremental] && options[:parallel]
          verify_parallel_accelerated options
        elsif options[:incremental]
          verify_incremental options
        else
          verify_one_shot options
        end
      end

      def verify_one_shot(options = {})
        unroll = options[:unroll]
        delays = options[:delays]
        if trace = vvvvv(options)
          puts "Got a trace w/ depth #{unroll || "inf."} and #{delays} delays." unless $quiet
        else
          puts "Verified w/ depth #{unroll || "inf."} and #{delays} delays." unless $quiet
        end
        return trace
      end

      def verify_incremental(options = {})
        unroll_bound = options[:unroll] || Float::INFINITY
        delay_bound = options[:delays] || Float::INFINITY

        unroll = 0
        delays = 0

        while true
          Kernel::print "Verifying w/ depth #{unroll} and #{delays} delays..." unless $quiet
          Kernel::print "\r" unless $quiet

          break if trace = vvvvv(options.merge(unroll: unroll, delays: delays))
          break if delays >= delay_bound && unroll >= unroll_bound

          if (delays < delay_bound && delays < unroll) || unroll >= unroll_bound
            delays += 1
          else
            unroll += 1
          end
        end

        if trace
          puts "Got a trace w/ depth #{unroll} and #{delays} delays." unless $quiet
        else
          puts "Verified up to depth #{unroll} w/ #{delays} delays." unless $quiet
        end

        return trace
      end

      def verify_parallel_accelerated(options = {})
        unroll_bound = options[:unroll] || Float::INFINITY
        delay_bound = options[:delays] || Float::INFINITY

        done = 0

        unroll_lower = 0
        delay_lower = 0

        tasks = [nil, nil]
        start = Time.now
        trace = nil

        EventMachine.run do
          EventMachine.add_periodic_timer(0.5) do
            Kernel::print \
              "Verifying in parallel w/ unroll/delays " \
              "#{tasks[0] ? "#{tasks[0][:unroll]}/#{tasks[0][:delays]}" : "-/-"} " \
                "(#{tasks[0] ? (Time.now - tasks[0][:time]).round : "-"}s) and " \
              "#{tasks[1] ? "#{tasks[1][:unroll]}/#{tasks[1][:delays]}" : "-/-"} " \
                "(#{tasks[1] ? (Time.now - tasks[1][:time]).round : "-"}s) " \
              "total #{(Time.now - start).round}s" \
              "\r" unless $quiet
          end

          (0..1).each do |i|
            EventMachine.defer do
              while true
                unroll = unroll_lower
                delays = delay_lower
                mode = tasks[i] ? tasks[i][:mode] : (i == 0 && :unroll || i == 1 && :delay)
                mode = :unroll if delays == delay_bound
                mode = :delay if unroll == unroll_bound
                unroll += 1 if mode == :unroll
                delays += 1 if mode == :delay
                if unroll > unroll_bound || delays > delay_bound
                  tasks[i] = nil
                  break
                end
                tasks[i] = {mode: mode, time: Time.now, unroll: unroll, delays: delays}

                if trace = vvvvv(options.merge(unroll: unroll, delays: delays)) then
                  EventMachine.stop
                  puts unless $quiet
                  puts "Got a trace w/ depth #{unroll} and #{delays} delays." unless $quiet
                  break
                end
                unroll_lower += 1 if i == 0
                delay_lower += 1 if i == 1
              end
              if (done += 1) >= 2
                EventMachine.stop
                puts unless $quiet
              end
            end
          end
        end

        puts "Verified up to depth #{unroll_bound} w/ #{delay_bound} delays." \
          unless trace || $quiet

        return trace
      end

      def verify_parallel_worklist(options = {})
        unroll_bound = options[:unroll] || Float::INFINITY
        delay_bound = options[:delays] || Float::INFINITY

        covered = []
        worklist = [{unroll: 0, delays: 0}, {unroll: 1, delays: 0}]
        tasks = [nil, nil]
        start = Time.now
        trace = nil
        idle = 0

        # EventMachine.threadpool_size = 2
        EventMachine.run do
          EventMachine.add_periodic_timer(0.5) do
            Kernel::print \
              "Verifying in parallel w/ unroll/delays " \
              "#{tasks[0] ? "#{tasks[0][:unroll]}/#{tasks[0][:delays]}" : "-/-"} " \
                "(#{tasks[0] ? (Time.now - tasks[0][:time]).round : "-"}s) and " \
              "#{tasks[1] ? "#{tasks[1][:unroll]}/#{tasks[1][:delays]}" : "-/-"} " \
                "(#{tasks[1] ? (Time.now - tasks[1][:time]).round : "-"}s) " \
              "total #{(Time.now - start).round}s" \
              "\r" unless $quiet
          end

          (0..1).each do |i|
            EventMachine.defer do
              while true
                work = worklist.shift
                break unless work
                unroll = work[:unroll]
                delays = work[:delays]
                next if covered.any?{|w| w[:unroll] >= unroll && w[:delays] >= delays}
                covered.reject!{|w| w[:unroll] <= unroll && w[:delays] <= delays}
                covered << work

                tasks[i] = {time: Time.now, unroll: unroll, delays: delays}

                if trace = vvvvv(options.merge(unroll: unroll, delays: delays)) then
                  EventMachine.stop
                  puts unless $quiet
                  puts "Got a trace w/ depth #{unroll} and #{delays} delays." unless $quiet
                  break
                else
                  worklist.reject!{|w| w[:unroll] <= unroll && w[:delays] <= delays}
                  worklist << {unroll: unroll+1, delays: delays} if unroll < unroll_bound
                  worklist << {unroll: unroll, delays: delays+1} if delays < delay_bound
                end
              end
              tasks[i] = nil
              EventMachine.stop if (idle += 1) >= 2
            end
          end
        end

        puts "Verified up to depth #{unroll_bound} w/ #{delay_bound} delays." \
          unless trace || $quiet
        return trace
      end

      def vvvvv(options = {})
        boogie_opts = []

        orig = source_file || "a.bpl"
        base = File.basename(orig).chomp(File.extname(orig))
        $temp << src = "#{base}.c2s.#{Time.now.to_f}.bpl"
        $temp << model_file = src.chomp('.bpl') + '.model'
        $temp << trace_file = src.chomp('.bpl') + '.trace'

        unless options[:unroll]
          case options[:verifier]
          when :boogie_fi
            warn "without loop unrolling, Boogie may be imprecise"
          else
            warn "without specifying an unroll bound, Boogie may not terminate"
          end
        end

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
        boogie_opts << "/printModelToFile:#{model_file}"
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

        cmd = "#{boogie} #{src} #{boogie_opts * " "} 1> #{trace_file}"
        puts cmd.bold if $verbose
        t = Time.now

        system cmd
        output = File.read(trace_file).lines

        if output.grep(/Boogie program verifier finished/).empty?
          abort begin
            "there was a problem running Boogie." +
            ($verbose ? "\n" + output.drop(1) * "\n" : "")
          end
        end
        
        has_errors = output.last.match(/(\d+) error/){|m| m[1].to_i > 0}

        if has_errors
          model = Z3::Model.new(model_file)
          trace = Trace.new(trace_file, model)
        else
          trace = nil
        end

        return trace

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

    end

  end
end
