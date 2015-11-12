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
          proc.add_attribute :atomic
          if proc.body && proc.body.any? {|x| x.has_attribute? :yield}
            work_list << proc
          end
        end

        until work_list.empty?
          proc = work_list.shift
          proc.remove_attribute :atomic
          targets = proc.callers
          targets << proc.declaration if proc.respond_to?(:declaration) && proc.declaration
          targets.each do |caller|
            next unless caller.has_attribute?(:atomic)
            work_list |= [caller]
          end
        end
      end

    end
  end
end
