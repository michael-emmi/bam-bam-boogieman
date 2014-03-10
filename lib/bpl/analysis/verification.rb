
module Bpl
  module AST

    class Program

      def verify(options = {})
        if options[:incremental] && options[:parallel]
          verify_incremental_in_parallel options
        elsif options[:incremental]
          verify_incremental options
        else
          verify_one_shot options
        end
      end

      def verify_one_shot(options = {})
        if vvvvv(options)
          puts "Got a trace..." unless $quiet
        else
          puts "Verified w/ depth #{options[:unroll]} and #{options[:delays]} delays." unless $quiet
        end
      end

      def verify_incremental(options = {})
        unroll_bound = options[:unroll] || Float::INFINITY
        delay_bound = options[:delays] || Float::INFINITY

        unroll = 0
        delays = 0

        while true
          if delays > delay_bound
            puts unless $quiet
            puts "Verified up to depth #{unroll} w/ #{delays-1} delays." unless $quiet
            break
          end

          Kernel::print "Verifying w/ depth #{unroll} and #{delays} delays..." unless $quiet
          Kernel::print "\r" unless $quiet

          if vvvvv(options.merge(unroll: unroll, delays: delays))
            puts unless $quiet
            puts "Got a trace..." unless $quiet
            break
          end

          if (delays < delay_bound && delays < unroll) || unroll >= unroll_bound
            delays += 1
          else
            unroll += 1
          end
        end
      end

      def verify_incremental_in_parallel(options = {})
        unroll_bound = options[:unroll] || Float::INFINITY
        delay_bound = options[:delays] || Float::INFINITY

        done = 0
        unroll_lower = 0
        delay_lower = 0

        times = [Time.now, Time.now]

        EventMachine.run do
          EventMachine.add_periodic_timer(1) do
            Kernel::print "Verifying in parallel w/ depth #{unroll_lower} and #{delay_lower} delays" unless $quiet
            Kernel::print " / time #{times.map{|t| "#{(Time.now - t).round}s" } * ", "}" unless $quiet
            Kernel::print "\r" unless $quiet
          end

          (0..1).each do |i|
            EventMachine.defer do
              while true
                unroll = unroll_lower
                delays = delay_lower
                times[i] = Time.now
                if vvvvv(options.merge(unroll: unroll, delays: delays)) then
                  EventMachine.stop
                  puts unless $quiet
                  puts "Got a trace..." unless $quiet
                  break
                end

                case i
                when 0
                  if unroll_lower < unroll_bound
                    unroll_lower += 1
                  else
                    break
                  end
                else
                  if delay_lower < delay_bound
                    delay_lower += 1
                  else
                    break
                  end
                end

              end
              if (done += 1) >= 2
                EventMachine.stop
                puts unless $quiet
                puts "Verified up to depth #{unroll} w/ #{delays} delays." unless $quiet
              end
            end
          end
        end
      end

      # def verify_incremental_in_parallel(options = {})
      #   unroll_bound = options[:unroll] || Float::INFINITY
      #   delay_bound = options[:delays] || Float::INFINITY
      # 
      #   done = 0
      # 
      #   covered = []
      #   worklist = [{unroll: 0, delays: 0}, {unroll: 1, delays: 0}]
      # 
      #   # EventMachine.threadpool_size = 2
      #   EventMachine.run do
      #     (1..2).each do
      #       EventMachine.defer do
      #         while true
      #           work = worklist.shift
      #           break unless work
      #           unroll = work[:unroll]
      #           delays = work[:delays]
      #           break if covered.any?{|w| w[:unroll] >= unroll && w[:delays] >= delays}
      #           covered.reject!{|w| w[:unroll] <= unroll && w[:delays] <= delays}
      #           covered << work
      # 
      #           puts "Verifying w/ #{unroll} unroll and #{delays} delays." unless $quiet
      #           if vvvvv(options.merge(unroll: unroll, delays: delays)) then
      #             EventMachine.stop
      #             puts "Got a trace..." unless $quiet
      #             break
      #           else
      #             worklist.reject!{|w| w[:unroll] <= unroll && w[:delays] <= delays}
      #             worklist << {unroll: unroll+1, delays: delays} if unroll < unroll_bound
      #             worklist << {unroll: unroll, delays: delays+1} if delays < delay_bound
      #           end
      #         end
      #         EventMachine.stop if (done += 1) >= 2
      #       end
      #     end
      #   end
      # end

      def vvvvv(options = {})
        boogie_opts = []

        orig = source_file || "a.bpl"
        base = File.basename(orig).chomp(File.extname(orig))
        src = "#{base}.c2s.#{Time.now.to_f}.bpl"
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

        if File.read(trace).lines.last.match(/(\d+) error/){|m| m[1].to_i > 0}
          err_trace = Trace.new(trace)
        else
          err_trace = nil
        end

        File.unlink(src) unless $keep
        File.unlink(trace) unless $keep
        File.unlink(model) unless $keep || !File.exists?(model)

        return err_trace

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
