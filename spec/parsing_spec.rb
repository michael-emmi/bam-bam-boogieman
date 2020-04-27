# typed: false
require 'bpl/parser.tab'

describe Bpl do

  # TODO add more parsing tests

  it "can parse basic language features" do
    adt = BoogieLanguage.new.parse <<~STRING
      var $glob: int;

      procedure {:some_attr} some_proc(x: int)
      requires true;
      ensures true;
      modifies $glob;
      {
        if (*) {
          $glob := 0;
        } else {
          $glob := 1;
        }
        return;
      }
    STRING

    expect(adt).not_to be nil

    expect(adt.any? do |decl|
      decl.is_a?(VariableDeclaration) &&
      decl.type == Type::Integer &&
      decl.names.length == 1 &&
      decl.names.any? {|id| id == "$glob"}
    end).to be true

    expect(adt.any? do |decl|
      decl.is_a?(ProcedureDeclaration) &&
      decl.names.any? {|id| id == "some_proc"} &&
      decl.any? {|a| a.is_a?(Attribute)} &&
      decl.any? {|s| s.is_a?(RequiresClause)} &&
      decl.any? {|s| s.is_a?(EnsuresClause)} &&
      decl.any? {|s| s.is_a?(ModifiesClause)}
    end).to be true

    expect(adt.any? do |stmt|
      stmt.is_a?(IfStatement) &&
      stmt.any? {|e| e == Expression::Wildcard} &&
      stmt.any? {|s| s.is_a?(AssignStatement)} &&
      stmt.else
    end).to be true
  end
end
