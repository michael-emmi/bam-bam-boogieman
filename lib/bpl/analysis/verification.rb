
module Bpl
  module Analysis
    class Verification < Bpl::Pass
      def self.description
        "Verify the program."
      end

      option :verifier, "which verifier to use (boogie, corral, ...)"
      option :incremental, "do incremental verification?"
      option :parallel, "do verification in parallel?"
      option :unroll, "the loop/procedure unrolling bound"
      option :timeout, "verifier time limit"
      option :trace_file, "file for storage of traces"
      option :debug_solver, "enable solver debugging"

      def run!(program, options = {})

        # begin
        #   require 'eventmachine'
        # rescue LoadError
        #   warn "Parallel verification requires the eventmachine gem; disabling." if @parallel
        #   @parallel = false
        # end

        if options[:incremental] && options[:parallel]
          verify_parallel_accelerated program, options
        elsif options[:incremental]
          verify_incremental program, options
        else
          verify_one_shot program, options
        end
      end

      def verify_one_shot(program, options = {})
        unroll = options[:unroll]
        rounds = options[:rounds]

        done = false
        trace = nil
        start = Time.now

        printer = Thread.new do
          until done do
            print (" " * 80 + "\r")
            print \
              "Verifying w/ depth #{unroll || "inf."} and #{rounds} rounds " \
              "(#{(Time.now - start).round}s)" \
              "\r" unless $quiet
            sleep 1
          end
        end

        trace = vvvvv(program, options)
        done = true
        printer.join
        puts unless $quiet

        if trace == :timeout
          puts "Verification timed out." unless $quiet
        elsif trace
          puts "Got a trace w/ depth #{unroll || "inf."} and #{rounds} rounds." unless $quiet
        else
          puts "Verified w/ depth #{unroll || "inf."} and #{rounds} rounds." unless $quiet
        end
        return trace
      end

      def verify_incremental(program, options = {})
        unroll_bound = options[:unroll] || Float::INFINITY
        rounds_bound = options[:rounds] || Float::INFINITY

        unroll = 0
        rounds = 1

        done = false
        trace = nil
        last = start = Time.now

        printer = Thread.new do
          until done do
            print (" " * 80 + "\r")
            print \
              "Verifying w/ depth #{unroll} and #{rounds} rounds " \
              "(#{(Time.now - last).round}s) total #{(Time.now - start).round}s" \
              "\r" unless $quiet
            sleep 1
          end
        end

        while true
          last = Time.now
          break if trace = vvvvv(program, options.merge(unroll: unroll, rounds: rounds))
          break if round >= rounds_bound && unroll >= unroll_bound

          if (rounds < rounds_bound && rounds < unroll) || unroll >= unroll_bound
            rounds += 1
          else
            unroll += 1
          end
        end
        done = true
        printer.join
        puts unless $quiet

        if trace == :timeout
          puts "Verification timed out." unless $quiet
        elsif trace
          puts "Got a trace w/ depth #{unroll} and #{rounds} rounds." unless $quiet
        else
          puts "Verified up to depth #{unroll} w/ #{rounds} rounds." unless $quiet
        end

        return trace
      end

      def verify_parallel_accelerated(program, options = {})
        unroll_bound = options[:unroll] || Float::INFINITY
        rounds_bound = options[:rounds] || Float::INFINITY

        done = 0

        unroll_lower = 0
        round_lower = 0

        tasks = [nil, nil]
        start = Time.now
        trace = nil

        EventMachine.run do
          EventMachine.add_periodic_timer(0.5) do
            print (" " * 80 + "\r")
            print \
              "Verifying in parallel w/ unroll/rounds " \
              "#{tasks[0] ? "#{tasks[0][:unroll]}/#{tasks[0][:rounds]}" : "-/-"} " \
                "(#{tasks[0] ? (Time.now - tasks[0][:time]).round : "-"}s) and " \
              "#{tasks[1] ? "#{tasks[1][:unroll]}/#{tasks[1][:rounds]}" : "-/-"} " \
                "(#{tasks[1] ? (Time.now - tasks[1][:time]).round : "-"}s) " \
              "total #{(Time.now - start).round}s" \
              "\r" unless $quiet
          end

          (0..1).each do |i|
            EventMachine.defer do
              while true
                unroll = unroll_lower
                rounds = round_lower
                mode = tasks[i] ? tasks[i][:mode] : (i == 0 && :unroll || i == 1 && :rounds)
                mode = :unroll if rounds == rounds_bound
                mode = :rounds if unroll == unroll_bound
                unroll += 1 if mode == :unroll
                rounds += 1 if mode == :rounds
                if unroll > unroll_bound || rounds > round_bound
                  tasks[i] = nil
                  break
                end
                tasks[i] = {mode: mode, time: Time.now, unroll: unroll, rounds: rounds}

                if trace = vvvvv(program, options.merge(unroll: unroll, rounds: rounds)) then
                  EventMachine.stop
                  puts unless $quiet
                  if trace == :timeout
                    puts "Verification timed out." unless $quiet
                  else
                    puts "Got a trace w/ depth #{unroll} and #{rounds} rounds." unless $quiet
                  end
                  break
                end
                unroll_lower += 1 if i == 0
                rounds_lower += 1 if i == 1
              end
              if (done += 1) >= 2
                EventMachine.stop
                puts unless $quiet
              end
            end
          end
        end

        puts "Verified up to depth #{unroll_bound} w/ #{rounds_bound} rounds." \
          unless trace || $quiet

        return trace
      end

      def verify_parallel_worklist(program, options = {})
        unroll_bound = options[:unroll] || Float::INFINITY
        # round_bound = options[:rounds] || Float::INFINITY

        covered = []
        worklist = [{unroll: 0, rounds: 0}, {unroll: 1, rounds: 0}]
        tasks = [nil, nil]
        start = Time.now
        trace = nil
        idle = 0

        # EventMachine.threadpool_size = 2
        EventMachine.run do
          EventMachine.add_periodic_timer(0.5) do
            print (" " * 80 + "\r")
            print \
              "Verifying in parallel w/ unroll/rounds " \
              "#{tasks[0] ? "#{tasks[0][:unroll]}/#{tasks[0][:rounds]}" : "-/-"} " \
                "(#{tasks[0] ? (Time.now - tasks[0][:time]).round : "-"}s) and " \
              "#{tasks[1] ? "#{tasks[1][:unroll]}/#{tasks[1][:rounds]}" : "-/-"} " \
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
                rounds = work[:rounds]
                next if covered.any?{|w| w[:unroll] >= unroll && w[:rounds] >= rounds}
                covered.reject!{|w| w[:unroll] <= unroll && w[:rounds] <= rounds}
                covered << work

                tasks[i] = {time: Time.now, unroll: unroll, rounds: rounds}

                if trace = vvvvv(program, options.merge(unroll: unroll, rounds: rounds)) then
                  EventMachine.stop
                  puts unless $quiet
                  if trace == :timeout
                    puts "Verification timed out." unless $quiet
                  else
                    puts "Got a trace w/ depth #{unroll} and #{rounds} rounds." unless $quiet
                  end
                  break
                else
                  worklist.reject!{|w| w[:unroll] <= unroll && w[:rounds] <= rounds}
                  worklist << {unroll: unroll+1, rounds: rounds} if unroll < unroll_bound
                  worklist << {unroll: unroll, rounds: rounds+1} if rounds < rounds_bound
                end
              end
              tasks[i] = nil
              EventMachine.stop if (idle += 1) >= 2
            end
          end
        end

        puts "Verified up to depth #{unroll_bound} w/ #{rounds_bound} rounds." \
          unless trace || $quiet
        return trace
      end

      def vvvvv(program, options = {})
        boogie_opts = []

        orig = program.source_file || "a.bpl"
        base = File.basename(orig).chomp(File.extname(orig))
        $temp << src = "#{base}.bam.#{Time.now.to_f}.bpl"
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
          prepare_for_boogie_fi!(program, options[:unroll])

        when :boogie_si
          boogie_opts << "/stratifiedInline:2"
          boogie_opts << "/extractLoops"
          boogie_opts << "/recursionBound:#{options[:unroll]}" if options[:unroll]
          boogie_opts << "/weakArrayTheory"
          boogie_opts << "/siVerbose:1" if $verbose
          prepare_for_boogie_si! program

        else
          err "invalid back-end: #{options[:verifier]}"
        end

        # boogie_opts << "/useArrayTheory" # NOTE always slower for mje

        boogie_opts << "/errorLimit:1"
        boogie_opts << "/errorTrace:2"
        boogie_opts << "/printModel:4"
        boogie_opts << "/printModelToFile:#{model_file}"
        boogie_opts << "/removeEmptyBlocks:0" # XXX
        boogie_opts << "/coalesceBlocks:0"    # XXX

        boogie_opts << "/timeLimit:#{options[:timeout]}" if options[:timeout]
        boogie_opts << "/proverOpt:C:TRACE=true" if options[:debug_solver]

        if program.declarations.any?{|d| d.is_a?(ConstantDeclaration) && d.names.include?('#ROUNDS')}
          program.declarations.push bpl("axiom #ROUNDS == #{options[:rounds]};")
        end
        if program.declarations.any?{|d| d.is_a?(FunctionDeclaration) && d.name == '$R'}
          (0..(options[:rounds]-1)).each do |i|
            program.declarations.push bpl("axiom $R(#{i});")
          end
        end
        File.write(src,program)
        if program.declarations.any?{|d| d.is_a?(ConstantDeclaration) && d.names.include?('#ROUNDS')}
          program.declarations.pop
        end

        cmd = "#{boogie} #{src} #{boogie_opts * " "} 1> #{trace_file}"
        puts cmd.bold if $verbose
        # t = Time.now

        system cmd
        output = File.read(trace_file).lines

        if output.grep(/Boogie program verifier finished/).empty?
          abort begin
            "there was a problem running Boogie." +
            ($verbose ? "\n" + output.drop(1) * "\n" : "")
          end
        end

        has_errors = output.last.match(/(\d+) error/){|m| m[1].to_i > 0}
        timeout = output.last.match(/(\d+) time out/){|m| m[1].to_i > 0}

        if timeout
          trace = :timeout
        elsif has_errors
          model = Z3::Model.new(model_file)
          trace = Trace.new(trace_file, program, model)
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

      def prepare_for_boogie_fi! program, unroll
        add_inline_annotations! program, unroll
      end

      def add_inline_annotations! program, unroll
        program.declarations.each do |d|
          if d.is_a?(ProcedureDeclaration) && d.body && !d.is_entrypoint?
            d.attributes[:inline] = [bpl("#{unroll || 1}")]
          end
        end
      end

      def prepare_for_boogie_si! program
        program.declarations.each do |proc|
          next unless proc.is_entrypoint?
          proc.body.each do |stmt|
            next unless stmt.is_a?(AssertStatement)
            stmt.remove
          end
        end
      end

    end
  end
end
