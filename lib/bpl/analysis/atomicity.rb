module Bpl
  module Analysis
    class Atomicity < Bpl::Pass
      def self.description
        "Mark atomic procedures."
      end

      def run! program
        work_list = []
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration)
          proc.attributes[:atomic] = []
          if proc.body && proc.body.any? {|x| x.attributes.include? :yield}
            work_list << proc
          end
        end

        until work_list.empty?
          proc = work_list.shift
          proc.attributes.delete :atomic
          targets = proc.callers
          targets << proc.declaration if proc.respond_to?(:declaration) && proc.declaration
          targets.each do |caller|
            next unless caller.attributes.include?(:atomic)
            work_list |= [caller]
          end
        end
      end

    end
  end
end
