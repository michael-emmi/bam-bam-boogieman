module Bpl
  module Transformation
    class Inlining < Bpl::Pass
      def self.description
        "Inline procedures."
      end

      def run! program
        $temp << source = "bam.#{Time.now.to_f}.bpl"
        $temp << inlined = "bam.inlined.#{Time.now.to_f}.bpl"

        File.write(source,program)
        cmd = "#{boogie} /noVerify /printInlined #{source} 1> #{inlined} 2>&1"
        abort "Failed to invoke Boogie for inlining" unless system cmd
        inlined = File.read(inlined)
        2.times do
          inlined = inlined.slice(inlined.index("\n") + 1 .. inlined.rindex("\n")-1)
        end

        inlined = timed 'Parsing' do
          BoogieLanguage.new.parse(inlined)
        end

        program.declarations.each do |decl|
          next if decl.is_a?(ProcedureDeclaration) && decl.body
          inlined.declarations << decl
        end

        resolve! inlined
        correct_modifies! inlined
        return inlined
      end
    end
  end
end
