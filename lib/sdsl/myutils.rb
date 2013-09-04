# myutils.rb
# misc. utility stuff
#
# TODO: decisions to mull over 
# - just use symbols for data?
#

require 'PP'

DOT_FILE = "out.dot"
ALLOY_FILE = "out.als"
FONTNAME = "courier"
UNIT = "UNIT"
UNIVERSAL_FIELDS = ["trigger"]
ALLOY_CMDS = "
fun RelevantOp : Op -> Step {
	{o : Op, t : Step | o.post = t and o in SuccessOp}
}

run SanityCheck {
	all m : Module |
		some sender.m & SuccessOp
} for 1 but 9 Data, 10 Step, 9 Op

check Confidentiality {
   Confidentiality 
} for 1 but 9 Data, 10 Step, 9 Op

-- check who can create CriticalData
check Integrity {
   Integrity
} for 1 but 9 Data, 10 Step, 9 Op
"

class Array
  def to_alloy(ctx=nil)
    self.map { |e| e.to_alloy(ctx) }.join(" and ")
  end
end

class Symbol
  def method_missing(n, *args, &block)
    if args.count > 1
      raise "Symbol.method_missing: Invalid number of arguments!"
    end
    e(self).send(n, args[0])
  end
end

# String utils
def wrap(s, t=0)  
  ("\t"*t) + s + "\n"
end

def tab(s, t=0)
  ("\t"*t) + s
end

def append(s1, s2)
  s1 + s2 + "\n"
end

def enclose s
  "(" + s + ")"
end

def writeComment comment
  wrap("\n-- #{comment}")
end

def writeFacts(fname, facts)
  if facts.empty? 
    ""
  else 
    str = writeComment("fact #{fname}")
    str += wrap("fact " + fname + " {")
    facts.each do |f|
      str += wrap(f, 1)
    end
    str += wrap("}")
  end
end

def dotModule m 
  "#{m.name} [shape=component];"
end

def dotOpName(m, o)
  "#{m.name}_#{o.name}"
end

def dotOp(m, o)
  "#{dotOpName(m, o)} [label=\"#{o.name}\",shape=rectangle,style=\"rounded\"];"
end

def writeDot(mods, dotFile)
  f = File.new(dotFile, 'w')
  f.puts "digraph g {"
  f.puts 'graph[fontname="' + FONTNAME + '", splines=true, concentrate=true];'
  f.puts 'node[fontname="' + FONTNAME + '"];'
  f.puts 'edge[fontname="' + FONTNAME + '", len=1.0];'
  mods.each do |m|
    f.puts "subgraph cluster_#{m.name} { " 
    f.puts "style=filled; color=lightgrey;"
    f.puts(dotModule m)
    m.exports.each do |e|
      f.puts(dotOp(m, e))
      f.puts("#{m.name} -> #{dotOpName(m, e)} [style=dashed,dir=none];")
    end
    f.puts "}"
    m.invokes.each do |i|
      mods.each do |m2|
        if m2.exports.any? { |i2| i2.name == i.name}
          f.puts("#{m.name} -> #{dotOpName(m2, i)};")
        end
      end
    end
  end
  f.puts "}"
  f.close
end

def dumpAlloy(v, alloyFile = ALLOY_FILE)
  f = File.new(alloyFile, 'w')
  # headers
  f.puts "open models/basic"
  f.puts "open models/crypto[Data]"
  f.puts
  f.puts v.to_alloy
  # footers
  f.puts
  f.puts ALLOY_CMDS
  f.close
end

def drawView(v, dotFile=DOT_FILE)
  writeDot v.modules, dotFile
end

#########################################
# Relations
class Rel
end

# Unary rel with multiplicity lone
class Item < Rel
  attr_reader :name, :type
  def initialize(n, t)
    @name = n
    @type = t
  end
  def to_s
    @name.to_s
  end
  def to_alloy(ctx=nil)
    @name.to_s + " : lone " + @type.to_s
  end
  def rewrite(ctx)
    Item.new(@name, @typ)
  end
  def ==(other)
    other.equal?(self) ||
    (other.instance_of?(self.class) && 
     other.name == self.name && 
     other.type == self.type)
  end

end
def item(n, t)
  Item.new(n, t)
end

# Alloy set
class Bag < Rel
  attr_reader :name, :type
  def initialize(n, t)
    @name = n
    @type = t
  end
  def to_s
    @name.to_s
  end
  def to_alloy(ctx=nil)
    @name.to_s + " : set " + @type.to_s
  end
  def rewrite(ctx)
    Bag.new(@name, @typ)
  end
  def ==(other)
    other.equal?(self) ||
    (other.instance_of?(self.class) && 
     other.name == self.name && 
     other.type == self.type)
  end

end
def set(n, t)
  Bag.new(n, t)
end

# Functions
class Map < Rel
  attr_reader :name, :type1, :type2
  def initialize(n, t1, t2)
    @name = n
    @type1 = t1
    @type2 = t2
  end
  def to_s
    @name.to_s
  end
  def to_alloy(ctx=nil)
    @name.to_s + " : " + @type1.to_s + " -> " + @type2.to_s  
  end
  def rewrite(ctx)
    Map.new(@name,@type1,@type2)
  end

  def ==(other)
    other.equal?(self) ||
    (other.instance_of?(self.class) && 
     other.name == self.name && 
     other.type1 == self.type1 &&
     other.type2 == self.type2)
  end

end
def hasKey(m, i)
  if not m.is_a? Expr then m = expr(m) end
  if not i.is_a? Expr then i = expr(i) end
  some(nav(m, i))  
end

def myuniq(a)
  a2 = []
  a.each do |e|
    if not a2.include? e then a2 << e end
  end
  a2
end

# Expressions

class Expr
  def join otherExpr
    Join.new(self, otherExpr)
  end
  
  def contains otherExpr
    if not otherExpr.is_a? Expr then otherExpr = expr(otherExpr) end 
    some(intersect(self, otherExpr))
  end

  def eq otherExpr
    Equals.new(self, otherExpr)
  end
  
  def [] key
    if not key.is_a? Expr then key = expr(key) end  
    Nav.new(self, key)
  end

  def method_missing(n, *args, &block)
    self.join(expr(n))
  end
end

class AlloyExpr < Expr
  def initialize(e)
    @e = e
  end
  def to_s
    @e.to_s
  end
  def to_alloy(ctx=nil)
    @e.to_s
  end
  def rewrite(ctx)
    AlloyExpr.new(@e)
  end
end

def ae(e)
  AlloyExpr.new(e)
end

class SymbolExpr < Expr
  def initialize(e)
    @e = e
  end
  def to_s
    @e.to_s
  end
  def to_alloy(ctx=nil)
    @e.to_s
  end
  def rewrite(ctx)
    if ctx.has_key? @e
      tmp = nil
      ctx[@e].to_a.each do |e2|
        if tmp == nil
          tmp = SymbolExpr.new(e2)
        else 
          tmp = Union.new(tmp, op(e2))
        end
      end
      tmp
    else 
      SymbolExpr.new(@e)
    end
  end
end

def expr(e)
  SymbolExpr.new(e)
end
def e(e)
  expr(e)
end

class FuncApp < Expr
  def initialize(f, e)
    @f = f
    @e = e
  end
  def to_s
    "#{@f.to_s}[#{@e.to_s}]"
  end
  def to_alloy(ctx=nil)
    @f.to_alloy(ctx) + "[" + @e.to_alloy(ctx) +"]"
  end
  def rewrite(ctx)
    FuncApp.new(@f.rewrite(ctx), @e.rewrite(ctx))
  end
end

class OpExpr < Expr
  
  def initialize(e)  
    if not e.is_a? Symbol
      raise "Expected a symbol, but received #{e}"
    end
    @e = e
  end
  def to_s
    @e.to_s
  end

  def to_alloy(ctx=nil)
    @e.to_s
  end

  def rewrite(ctx)
    if ctx.has_key? @e
      tmp = nil
      ctx[@e].to_a.each do |e2|
        if tmp == nil
          tmp = OpExpr.new(e2)
        else 
          tmp = Union.new(tmp, op(e2))
        end
      end
      tmp
    else 
      OpExpr.new(@e)
    end
  end
end
def op(e)
  OpExpr.new(e)
end

class Union < Expr
  def initialize(e1, e2)
    @e1 = e1
    @e2 = e2
  end

  def to_s
    @e1.to_s + " \\/ " + @e2.to_s
  end

  def to_alloy(ctx=nil)
    enclose(@e1.to_alloy(ctx) + " + " + @e2.to_alloy(ctx))
  end

  def rewrite(ctx)
    Union.new(@e1.rewrite(ctx), @e2.rewrite(ctx))
  end

  def listify(ctx)
    l1 = []
    l2 = []
    if e1.is_a? Union
      l1 = @e1.listify(ctx)
    else 
      l1 = [@e1.to_alloy(ctx)]
    end
    if e2.is_a? Union
      l2 = @e2.listify(ctx)
    else
      l2 = [@e2.to_alloy(ctx)]
    end
    l1 + l2
  end
end

class Intersect < Expr
  def initialize(e1, e2)
    @e1 = e1
    @e2 = e2
  end
  def to_s
    @e1.to_s + " /\\ " + @e2.to_s
  end
  def to_alloy(ctx=nil)
    enclose(@e1.to_alloy(ctx) + " & " + @e2.to_alloy(ctx))
  end
  def rewrite(ctx)
    Intersect.new(@e1.rewrite(ctx), @e2.rewrite(ctx))
  end  
end
def intersect(e1, e2)
  if not e1.is_a? Expr then e1 = expr(e1) end
  if not e2.is_a? Expr then e2 = expr(e2) end
  Intersect.new(e1, e2)
end

# Navigation expr
class Nav < Expr
  def initialize(m, i)
    @map = m
    @index = i
  end
  def to_s
    @map.to_s + "[" + @index.to_s + "]"
  end
  def to_alloy(ctx=nil)
    @map.to_alloy(ctx) + "[" + @index.to_alloy(ctx) + "]"
  end
  def rewrite(ctx)
    Nav.new(@map.rewrite(ctx), @index.rewrite(ctx))
  end
end
def nav(m, i)
  if not m.is_a? Expr then m = expr(m) end
  if not i.is_a? Expr then i = expr(i) end  
  Nav.new(m, i)
end

class Join < Expr
  def initialize(r, c)
    @rel = r
    @col = c
  end
  def to_s
    @rel.to_s + "." + @col.to_s
  end
  def to_alloy(ctx=nil)
    e1 = @rel.to_alloy(ctx)
    e2 = @col.to_alloy(ctx)    

    if not UNIVERSAL_FIELDS.include? e2
      if e1 == "o"
        e2 = "(#{ctx[:op]} <: " + e2 + ")"
      elsif e1 == "o.trigger"
        e2 = enclose(ctx[:trigger].map { |t| enclose "#{t} <: #{e2}" }.join(" + "))
      end

    end
    e1 + "." + e2
  end
  def rewrite(ctx)
    Join.new(@rel.rewrite(ctx), @col.rewrite(ctx))
  end
end

def arg(arg, op = nil)
  if not op 
    e = expr(:o).join expr(arg)
  else 
    e = op.join expr(arg)
  end
  FuncApp.new(e(:arg), e)
end

def trig 
  expr(:o).join expr(:trigger)
end

def o
  expr(:o)
end

#########################################
# Formulas
class Formula 
  def and other
    And.new(self, other)
  end

  def or other
    Or.new(self, other)
  end
  
  def then other
    Implies.new(self, other)
  end

  def ==(other)
    other.equal?(self) ||
    (other.instance_of?(self.class) && 
     other.to_s == self.to_s)
  end
end

class AlloyFormula < Formula
  attr_reader :exp
  def initialize(f)
    @exp = f
  end
  def to_s
    exp
  end
  def to_alloy(ctx=nil)
    exp
  end
  def rewrite(ctx)
    AlloyFormula.new(ctx)
  end
end
def af(f)
  AlloyFormula.new(f)
end

class Unit < Formula
  def to_s
    UNIT
  end
  def is_unit?
    true
  end
  def to_alloy(ctx=nil)
    UNIT
  end
  def rewrite(ctx)
    self
  end
end

class Exists < Formula
  def initialize(e)
    @expr = e
  end  
  def to_s
    "Some(" + @expr.to_s + ")"
  end
  def to_alloy(ctx=nil)
    enclose("some " + @expr.to_alloy(ctx))
  end
  def rewrite(ctx)
    Exists.new(@expr.rewrite(ctx))
  end
end
def some(e)
  Exists.new(e)
end 

class Not < Formula
  def initialize(e)
    @expr = e
  end  
  def to_s
    "Not(" + @expr.to_s + ")"
  end
  def to_alloy(ctx=nil)
    enclose("not " + @expr.to_alloy(ctx))
  end
  def rewrite(ctx)
    Not.new(@expr.rewrite(ctx))
  end
end
def neg(e)
  Not.new(e)
end 

class No < Formula
  def initialize(e)
    @expr = e
  end  
  def to_s
    "No(" + @expr.to_s + ")"
  end
  def to_alloy(ctx=nil)
    enclose("no " + @expr.to_alloy(ctx))
  end
  def rewrite(ctx)
    No.new(@expr.rewrite(ctx))
  end
end
def no(e)
  No.new(e)
end 

class And < Formula
  attr_accessor :left, :right
  def initialize(f1, f2)
    @left = f1
    @right = f2
  end

  def to_s
    "And(" + left.to_s + "," + right.to_s + ")"
  end

  def to_alloy(ctx=nil)
    lformula = left.to_alloy(ctx)
    rformula = right.to_alloy(ctx)

    if lformula == UNIT or rformula == UNIT
      if lformula == UNIT then expr = enclose(rformula) end
      if rformula == UNIT then expr = enclose(lformula) end
      expr
    elsif lformula == rformula
      lformula
    else      
      enclose(lformula + " and " + rformula)
    end
  end

  def rewrite(ctx)
    And.new(@left.rewrite(ctx), @right.rewrite(ctx))
  end

end
def conj(f1, f2)
  And.new(f1, f2)
end
def conjs(fs)
  fs.inject(Unit.new) { |r, e| And.new(r, e) }
end

class Implies < Formula
  def initialize(e1, e2)
    @left = e1
    @right = e2
  end

  def to_s
    "Implies(" + @left.to_s + "," + @right.to_s + ")"
  end

  def to_alloy(ctx=nil)
    enclose(@left.to_alloy(ctx) + " implies " + @right.to_alloy(ctx))
  end

  def rewrite(ctx)
    Implies.new(@left.rewrite(ctx), @right.rewrite(ctx))
  end
end
def implies(f1, f2)
  Implies.new(f1, f2)
end

class Or < Formula
  attr_accessor :left, :right
  def initialize(f1, f2)
    @left = f1
    @right = f2
  end

  def to_s
    "Or(" + left.to_s + "," + right.to_s + ")"
  end

  def to_alloy(ctx=nil)
    ctx[:nesting] += 1
    lformula = left.to_alloy(ctx)
    rformula = right.to_alloy(ctx)

    ctx[:nesting] -= 1
    if lformula == UNIT or rformula == UNIT
      raise "An invalid OR expression: OR(" + lformula + "," + rformula + ")"
    elsif lformula == rformula
      str = lformula
    else
      str = wrap("")
      str += wrap("(#{lformula}", ctx[:nesting] + 1)
      str += wrap("or", ctx[:nesting] + 1)
      str += wrap("#{rformula}", ctx[:nesting] + 1)
      str += tab(")", ctx[:nesting] + 1)
#      str = enclose(lformula + " or " + rformula)       
    end
    str
  end

  def rewrite(ctx)
    Or.new(@left.rewrite(ctx), @right.rewrite(ctx))
  end
end
def disj(f1, f2)
  Or.new(f1, f2)
end

def union(flst1, flst2)
  if flst1.empty? && flst2.empty?
    []
  elsif flst1.empty?
    flst2
  elsif flst2.empty?
    flst1
  else 
    [disj(flst1.inject(Unit.new) { |r, f| conj(r, f)},
          flst2.inject(Unit.new) { |r, f| conj(r, f)})]
  end
end

class Equals < Formula
  def initialize(e1, e2)
    @left = e1
    @right = e2
  end

  def to_s
    "Equals(" + @left.to_s + "," + @right.to_s + ")"
  end

  def to_alloy(ctx=nil)
    @left.to_alloy(ctx) + " = " + @right.to_alloy(ctx)
  end

  def rewrite(ctx)
    Equals.new(@left.rewrite(ctx), @right.rewrite(ctx))
  end
end

class Pred2App < Formula
  def initialize(pred, a1, a2)
    @pred = pred
    @a1 = a1
    @a2 = a2
  end

  def to_s
    @pred.to_s + "[" + @a1.to_s + "," + @a2.to_s + "]"
  end

  def to_alloy(ctx=nil)
    pred = @pred.to_alloy(ctx)
    a1 = @a1.to_alloy(ctx)
    a2 = @a2.to_alloy(ctx)
    
    if pred == "triggeredBy"
      if @a2.is_a? Union
        ctx[:trigger] = @a2.listify(ctx)
      else        
        ctx[:trigger] = [a2.to_sym]
      end
    end
    pred + "[" + a1 + "," + a2 + "]"
  end  

  def rewrite(ctx)
    pred = @pred.rewrite(ctx)
    a1 = @a1.rewrite(ctx)
    a2 = @a2.rewrite(ctx)
    Pred2App.new(pred, a1, a2)
  end
end

def triggeredBy(t)
  Pred2App.new(e(:triggeredBy), e(:o), op(t))
end
