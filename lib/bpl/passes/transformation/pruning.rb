module Bpl
  class Pruning < Pass

    depends :resolution, :entrypoint_localization
    switch "--pruning", "Remove unreachable declarations."

    # TODO remove variables that are never read
    # TODO remove reads that are never used

    def run! program
      reachable = {}
      work_list = []
      program.declarations.each do |decl|
        next unless entrypoint_localization.entrypoints.include?(decl)
        reachable[decl] = Set.new(decl.names)
        work_list << decl
      end

      until work_list.empty?
        decl = work_list.shift
        decl.each do |elem|
          case elem
          when Identifier, CustomType
            d = elem.declaration
            n = elem.name
            unless d.nil? || (reachable[d] && reachable[d].include?(n))
              reachable[d] ||= Set.new
              reachable[d] << n
              work_list |= [d]
            end
          end
        end
        decl.bindings.each do |elem|
          ax = elem.each_ancestor.find{|d| d.is_a?(AxiomDeclaration)}
          unless ax.nil? || reachable[ax]
            reachable[ax] = Set.new
            work_list |= [ax]
          end
        end
      end

      program.declarations.each do |d|
        if reachable.include?(d)
          if d.instance_variable_defined?("@names")
            extras = d.names - reachable[d].to_a
            unless extras.empty?
              info "PRUNING UNUSED NAMES FROM DECLARATION"
              info
              info d.to_s.indent, (extras * ", ").indent
              info
              d.instance_variable_set "@names", reachable[d].sort
            end
          end
        else
          info "PRUNING UNUSED DECLARATION"
          info
          info d.to_s.indent
          info
          d.remove
        end
      end

    end

    def silly_expression?(expr)
      case expr
      when QuantifiedExpression
        silly_expression?(expr.expression)
      when BinaryExpression
        silly_expression?(expr.lhs) && silly_expression?(expr.rhs)
      when FunctionApplication
        silly_expression?(expr.function)
      when Identifier
        !expr.declaration.has_attribute?(:reachable)
      else
        false
      end
    end
  end
end
