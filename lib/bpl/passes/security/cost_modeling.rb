module Bpl
  class CostModeling < Pass
    EXEMPTION_LIST = [
      '\$alloc',
      '\$free',
      'boogie_si_',
      '__VERIFIER_',
      '__SIDEWINDER_',
      '__SMACK_(?!static_init)',
      'llvm.dbg'
    ]

    EXEMPTIONS = /#{EXEMPTION_LIST * "|"}/

    STUB_ANNOTATION = :__VERIFIER_TIMING_CONTRACT

    def stub? decl
      decl.specifications.each.any? { |s| s.has_attribute? STUB_ANNOTATION }
    end

    LEAKAGE_ANNOTATION_NAME =  "__VERIFIER_ASSUME_LEAKAGE"

    def exempt? decl
      EXEMPTIONS.match(decl) && true
    end

    depends :normalization
    depends :ct_annotation, :cfg_construction
    depends :resolution, :loop_identification
    depends :definition_localization, :liveness
    invalidates :all
    switch "--cost-modeling", "Add cost-tracking variables."

    def is_annotation_stmt? (stmt, annot_name)
      return false unless stmt.is_a?(CallStatement)
      return stmt.procedure.to_s == annot_name
    end

    def has_annotation?(decl, annot_name)
      return false unless decl.body
      return (not (decl.body.select{|r| is_annotation_stmt?(r,annot_name)}.empty?))
    end
    

    #the annotation should have one argument, and we just want whatever it is
    def get_annotation_value annotationStmt
      raise "annotation should have one argument" unless annotationStmt.arguments.length == 1
      return annotationStmt.arguments.first.to_s
    end
    
    def annotate_function_body! decl
      if (has_annotation?(decl, LEAKAGE_ANNOTATION_NAME)) then
        decl.body.select{ |s| is_annotation_stmt?(s, LEAKAGE_ANNOTATION_NAME)}.each do |s| 
          value = get_annotation_value s
          s.insert_after(bpl("$l := $l + #{value};"))
        end
      else
        decl.body.select{ |s| s.is_a?(AssumeStatement)}.each do |stmt|
          next unless values = stmt.get_attribute(:'smack.InstTimingCost.Int64')
          stmt.insert_after(bpl("$l := $add.i32($l, #{values.first});"))
        end
      end
    end

    def redirect_to_stub! decl
      args, asmt = [], []
      decl.parameters.each {|d| args.push(d.names.flatten).flatten}
      decl.returns.each {|d| asmt.push(d.names.flatten).flatten}
      args, asmt = args.flatten, asmt.flatten
      stub_name = decl.specifications.first.get_attribute(STUB_ANNOTATION)&.first&.first
      stub_call = bpl("call #{asmt.join(",")} := #{stub_name}(#{args.join(",")});")
      myblock = Block.new(names: [], statements: [stub_call])
      decl.body.replace_children(:locals, [])
      decl.body.replace_children(:blocks, myblock)
    end

    def run! program
      # add cost global variable
      program.prepend_children(:declarations, bpl("var $l: int;"))

      # update cost global variable
      program.each_child do |decl|
        next unless decl.is_a?(ProcedureDeclaration)
        next if exempt?(decl.name)
        next unless decl.body

        redirect_to_stub!(decl) if stub?(decl)

        annotate_function_body! decl

      end

    end
  end
end
