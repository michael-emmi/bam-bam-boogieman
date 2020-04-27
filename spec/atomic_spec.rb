# typed: false
require 'bpl/parser.tab'
require 'bpl/passes/concurrency/atomic_annotation'

def get(root, name)
  root.find {|d| d.is_a?(ProcedureDeclaration) && d.names.any? {|id| id == name}}
end

describe Bpl do

  # TODO add more parsing tests

  it "can do atomic annotation" do
    adt = BoogieLanguage.new.parse <<~STRING
      procedure p() { assume {:yield} true; }
      procedure q() { }
      procedure r() { call p(); }
      procedure s() { call q(); }
      procedure t() { call p(); }
    STRING

    # XXX need to run dependencies too
    # Bpl::AtomicAnnotation.new().run! adt

    expect(get(adt, "p").has_attribute?("atomic")).to be false
    # expect(get(adt, "q").has_attribute?("atomic")).to be true
    expect(get(adt, "r").has_attribute?("atomic")).to be false
    # expect(get(adt, "s").has_attribute?("atomic")).to be true
    expect(get(adt, "t").has_attribute?("atomic")).to be false

    # expect(adt.any? do |decl|
    #
    # end).to be true
  end
end
