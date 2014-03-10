module C2S
  def self.violin_instrument! program, monitor
    
    methods = {}
    monitor_vars = []
    specs = []
    inits = []

    program.declarations +=
      BoogieLanguage.new.parse(File.read(monitor)).declarations
    
    program.declarations.each do |decl|
      if decl.is_a?(AxiomDeclaration) && decl.attributes.include?(:method)
        ax = decl.attributes[:method]
        methods.merge!({ax[0] => ax[1]})

      elsif decl.is_a?(VariableDeclaration) && decl.attributes.include?(:monitor_vars)
        monitor_vars += decl.names.map{|id| bpl(id)}

      elsif decl.is_a?(FunctionDeclaration) && decl.attributes.include?(:spec)
        specs << decl

      elsif decl.is_a?(ProcedureDeclaration) && decl.attributes.include?(:monitor_init)
        inits << decl
      end
    end
    
    program.declarations.each do |decl|
      case decl
      when ProcedureDeclaration
        
        next unless decl.body
        
        unless (new_mods = monitor_vars - decl.modifies).empty?
          decl.specifications << bpl("modifies #{new_mods * ", "};")
        end

        if methods.include?(decl.name)
          
          params = decl.parameters.map{|p| p.names}.flatten
          rets = ["$myop"] + decl.returns.map{|r| r.names}.flatten
          
          decl.body.declarations << bpl("var $myop: int;")
          decl.body.statements.unshift \
            bpl("call $myop := #{methods[decl.name]}.start(#{params * ","});")
          
          decl.body.replace do |elem|
            if elem.is_a?(ReturnStatement)
              next [
                bpl("call #{methods[decl.name]}.finish(#{rets * ","});"),
                bpl("return;") ]
            end
            elem
          end
        end
        
        decl.body.replace do |elem|
          case elem
          when AssumeStatement
            if elem.attributes.include? :startpoint
              next [elem] + inits.reverse.map{|init| bpl("call #{init.name}();")}
            end
          when AssertStatement
            if elem.attributes.include?(:spec) &&
              (ax = elem.attributes[:spec]) && !ax.empty? &&
              (name = ax.first) &&
              (spec = specs.detect{|s| s.name == name}) then
              next bpl("assert #{spec.name}(#{spec.arguments.map{|arg| arg.names}.flatten * ","});")
            end
          end
          elem
        end
        
      end
    end
    
  end
end