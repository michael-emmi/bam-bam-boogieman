module Bpl
  module Transformation
    class Shadowing < Bpl::Pass

      def self.description
        "Create a shadow program."
      end

      def shadow(x) "#{x}.shadow" end
      def decl(v) v.class.new(names: v.names.map(&method(:shadow)), type: v.type) end
      def expr(e)
        return e unless e.is_a?(StorageIdentifier)
        return e if e.declaration && e.declaration.is_a?(ConstantDeclaration)
        StorageIdentifier.new(name: shadow(e))
      end

      EXEMPTION_LIST = [
        '\$alloc',
        '\$free',
        'boogie_si_',
        '__VERIFIER_'
      ]
      EXEMPTIONS = /#{EXEMPTION_LIST * "|"}/

      def exempt? decl
        EXEMPTIONS.match(decl) && true
      end

      def run! program

        # duplicate global variables
        program.global_variables.each do |v|
          program << decl(v)
        end

        # duplicate parameters, returns, and local variables
        program.declarations.each do |decl|
          next unless decl.is_a?(ProcedureDeclaration)
          next if exempt?(decl.name)

          decl.parameters.map!{|v| [v,decl(v)]}.flatten!
          decl.returns.map!{|v| [v,decl(v)]}.flatten!

          next unless decl.body
          scope = [decl.body, decl, program]
          decl.body.declarations.map!{|v| [v,decl(v)]}.flatten!
          decl.body.each do |stmt|
            case stmt
            when AssignStatement, AssumeStatement
              stmt.insert_after(bpl(stmt.to_s, scope: scope).replace!(&method(:expr)))
            when CallStatement
              if exempt?(stmt.procedure.name)
                xs = stmt.assignments
                stmt.insert_after(bpl("#{xs.map{|v| shadow(v.name)} * ", "} := #{xs* ", "};", scope: scope)) unless xs.empty?
              else
                stmt.arguments.map!{|v| [v,bpl(v.to_s, scope:scope).replace!(&method(:expr))]}.flatten!
                stmt.assignments.map!{|v| [v,bpl(v.to_s, scope:scope).replace!(&method(:expr))]}.flatten!
              end
            end
          end
        end
      end
    end
  end
end
