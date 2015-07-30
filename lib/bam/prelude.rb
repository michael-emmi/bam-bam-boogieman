class String
  def to_range
    case self
    when /\d+\.\.\d+/
      split(/\.\./).inject{|i,j| i.to_i..j.to_i}
    else
      to_i..to_i
    end
  end

  def classify
    split('_').collect(&:capitalize).join
  end

  def unclassify
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end

  def hyphenate
    split('_').join('-')
  end

  def unhyphenate
    split('-').join('_')
  end

  def nounify
    split('_').collect(&:capitalize).join(' ')
  end

  def fmt
    self.split.join(' ').gsub(/\s*;/, ';')
  end

  def indent(n = 2)
    (" " * n) + gsub(/[\r\n]/,"\n#{" " * n}")
  end

  def comment
    "// " + gsub(/[\r\n]/,"\n// ")
  end

  def hilite
    underline
  end
end

class Symbol
  def hilite
    to_s.bold
  end
end

class String
  def yellow; self end
  def red; self end
  def green; self end
  def blue; self end
  def light_black; self end
  def bold; self end
  def underline; self end
end

begin
  require 'colorize'
rescue LoadError
end if $stdout.tty?

$warnings = Set.new
$show_warnings = true
$verbose = false
$quiet = false
$keep = false
$temp = Set.new

module Kernel

  alias :old_abort :abort

  def abort(str)
    old_abort("Error: #{str}".red)
  end

  def info(*args)
    args = [""] if args.empty?
    args.each do |str|
      puts ($stdout.tty? ? str.light_black : str.comment) unless $quiet
    end
  end

  def warn(*args)
    return unless $show_warnings
    args.each do |str|
      unless $warnings.include? str
        $stderr.puts "Warning: #{str}".yellow
        $warnings << str
      end
    end
  end

  def smack
    abort "'smackgen.py' missing from executable path.\n" \
      "The C/LLVM front end requires SMACK; please install it." \
    if `which smackgen.py`.empty?
    'smackgen.py --verifier=boogie-plain'
  end

  def boogie
    ['Boogie','boogie','Boogie.exe','boogie.exe'].each do |b|
      return "#{b}" if not `which #{b}`.empty?
    end
    abort "'Boogie' missing from executable path.\n" \
      "Verification requires Boogie; please install it."
  end

  def bpl(str)
    BoogieLanguage.new.parse_str(str)
  end

  def bpl_expr(str)
    BoogieLanguage.new.parse_expr(str)
  end

  def bpl_type(str)
    BoogieLanguage.new.parse_type(str)
  end
end

def timed(desc = nil)
  time = Time.now
  res = yield if block_given?
  time = (Time.now - time).round(2)
  info "#{desc} took #{time}s." if $verbose && desc
  res
end
