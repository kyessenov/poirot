# myutils.rb
# misc. utility stuff
#
# TODO: decisions to mull over
# - just use symbols for data?
#

UNIVERSAL_FIELDS = ["trigger"]

def keysWithVal (h, v)
  h.keys.find_all {|k| h[k] == v }
end

class Array
  def to_alloy(ctx=nil)
    self.map { |e| e.to_alloy(ctx) }.join(" and ")
  end

  def deepclone
    a = []
    each { |x| a << x.clone }
    a
  end
end

class Symbol
  def method_missing(n, *args, &block)
    return super unless $SDSL_EXE
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

# coerce both s1 and s2 to string and then compare
def scmp (s1, s2)
  s1.to_s == s2.to_s
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

def safeUnion(l1, l2)
  if (not l1 and not l2)
    nil
  elsif not l1 
    l2
  else 
    l1
  end
end

#########################################
# Relations
class Rel
end

class UnaryRel < Rel
  attr_reader :name, :type
  def initialize(n, t)
    @name = n
    @type = t
  end
  def to_s
    @name.to_s
  end
  def ==(other)
    other.equal?(self) ||
    (other.instance_of?(self.class) &&
     other.name == self.name &&
     other.type == self.type)
  end
end

# Unary rel with multiplicity "one"
class Item < UnaryRel
  def to_alloy(ctx=nil)
    @name.to_s + " : one " + @type.to_s
  end
  def rewrite(ctx)
    Item.new(@name, @typ)
  end
  def dynamic
    Map.new(name, type, STEP_TYPE, :one, :set)
  end
end
def item(n, t)
  Item.new(n, t)
end

# Unary rel with multiplicity "lone"
class Maybe < UnaryRel
  def to_alloy(ctx=nil)
    @name.to_s + " : lone " + @type.to_s
  end
  def rewrite(ctx)
    Item.new(@name, @typ)
  end
  def dynamic
    Map.new(name, type, STEP_TYPE, :lone, :set)
  end
end
def maybe(n, t)
  Maybe.new(n, t)
end

# Alloy set
class Bag < UnaryRel
  def to_alloy(ctx=nil)
    @name.to_s + " : set " + @type.to_s
  end
  def rewrite(ctx)
    Bag.new(@name, @typ)
  end
  def dynamic
    Map.new(name, type, STEP_TYPE, :set, :set)
  end
end
def set(n, t)
  Bag.new(n, t)
end

# Binary Rel
class Map < Rel
  attr_reader :name, :type1, :type2, :constr1, :constr2
  def initialize(n, t1, t2, c1=:set, c2=:lone)
    @name = n
    @type1 = t1
    @type2 = t2
    @constr1 = c1
    @constr2 = c2
  end
  def to_s
    @name.to_s
  end
  def to_alloy(ctx=nil)
    "#{@name} : #{@type1} #{@constr1} -> #{@constr2} #{type2}"
  end
  def rewrite(ctx)
    Map.new(@name,@type1,@type2, @constr1, @constr2)
  end

  def ==(other)
    other.equal?(self) ||
    (other.instance_of?(self.class) &&
     other.name == self.name &&
     other.type1 == self.type1 &&
     other.type2 == self.type2 &&
     other.constr1 == self.constr1 &&
     other.constr2 == self.constr2)
  end

  def dynamic
    TernaryRel.new(name, type1, type2, STEP_TYPE, constr1, constr2, :set)
  end
end

class TernaryRel < Rel
  attr_reader :name, :type1, :type2, :type3, :constr1, :constr2, :constr3
  def initialize(n, t1, t2, t3, c1=:set, c2=:set, c3=:set)
    @name = n
    @type1 = t1
    @type2 = t2
    @type3 = t3
    @constr1 = c1
    @constr2 = c2
    @constr3 = c3
  end
  def to_s
    @name.to_s
  end
  def to_alloy(ctx=nil)
    "#{@name} : (#{@type1} #{@constr1} -> #{@constr2} #{type2}) -> #{@constr3} #{type3}"
  end
  def rewrite(ctx)
    Map.new(@name,@type1,@type2, @type3, @constr1, @constr2, @constr3)
  end

  def ==(other)
    other.equal?(self) ||
    (other.instance_of?(self.class) &&
     other.name == self.name &&
     other.type1 == self.type1 &&
     other.type2 == self.type2 &&
     other.type3 == self.type3 &&
     other.constr1 == self.constr1 &&
     other.constr2 == self.constr2 &&
     other.constr3 == self.constr3)
  end
end

def hasKey(m, i)
  if not m.is_a? Expr then m = expr(m) end
  if not i.is_a? Expr then i = expr(i) end
  nav(m, i).some
end
def map(n, d, r)
  Map.new(n, d, r)
end
def rel(n, *t)
  case t.size
  when 1; item(n, t[0])
  when 2; map(n, t[0], t[1])
  else
    raise "only unary and binary relations supported"
  end
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
  def product otherExpr
    Product.new(self, otherExpr)
  end

  def union otherExpr
    Union.new(self, otherExpr)
  end

  alias_method :plus, :union

  def iplus(otherExpr)
    FuncApp.new(ae("plus"), self, otherExpr)
  end

  def join otherExpr
    Join.new(self, otherExpr)
  end

  def contains otherExpr
    if not otherExpr.is_a? Expr then otherExpr = expr(otherExpr) end
    intersect(self, otherExpr).some #TODO: this is not equivalent to `otherExpr in self'
  end

  def eq(otherExpr)  Equals.new(self, otherExpr) end
  def in(otherExpr)  otherExpr.contains(self) end
  def lt(otherExpr)  GenericBinOp.new(" < ", self, otherExpr) end
  def lte(otherExpr) GenericBinOp.new(" <= ", self, otherExpr) end
  def gt(otherExpr)  GenericBinOp.new(" > ", self, otherExpr) end
  def gte(otherExpr) GenericBinOp.new(" >= ", self, otherExpr) end

  def some()         Exists.new(self) end
  def no()           some.not end

  alias_method :equals, :eq

  def [] key
    if not key.is_a? Expr then key = expr(key) end
    Nav.new(self, key)
  end

  alias_method :select, :[]

  def method_missing(n, *args, &block)
    self.join(expr(n))
  end
end

# A generic Alloy expression
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

# Function application f(e)1,e_2,..,e_n)
class FuncApp < Expr
  def initialize(f, *e)
    @f = f
    @e = e
  end
  def to_s
    args = @e.map(&:to_s).join(', ')
    "#{@f.to_s}[#{args}]"
  end
  def to_alloy(ctx=nil)
    @f.to_alloy(ctx) + "[" + @e.map{|ee| ee.to_alloy(ctx)}.join(', ') +"]"
  end
  def rewrite(ctx)
    FuncApp.new(@f.rewrite(ctx), *@e.map{|ee| ee.rewrite(ctx)})
  end
end

class OpExpr < Expr
  def initialize(e)
    if e.is_a? String
      @e = e.to_sym
    elsif e.is_a? Symbol
      @e = e
    else
      raise "Expected a symbol or a string, but received #{e}"
    end
  end

  def to_s
    @e.to_s
  end

  def to_alloy(ctx=nil)
    @e.to_s
  end

  def rewrite(ctx)
    if ctx.has_key? @e and not ctx[@e].empty?
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

# Set union "+" in Alloy
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

# Set intersection "&" in Alloy
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

# Navigation expr "m[i]"
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

class BinOp < Expr
  def initialize(r, c)
    @rel = r
    @col = c
  end
  def op() fail "Must override" end
  def to_s
    @rel.to_s + op() + @col.to_s
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
    e1 + op() + e2
  end
  def rewrite(ctx)
    self.class.new(@rel.rewrite(ctx), @col.rewrite(ctx))
  end
end

class GenericBinOp < BinOp
  def initialize(op, lhs, rhs) 
    super(lhs, rhs)
    @op = op
  end
  def op() @op end
end

class Join < BinOp
  def op() "." end
end
class Product < BinOp
  def op() " -> " end
end

def arg(arg, op = nil)
  if not op
    e = expr(:o).join expr(arg)
  else
    e = op.join expr(arg)
  end
  #TODO: Not needed?
  #FuncApp.new(e(:arg), e)
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

  alias_method :implies, :then

  def not
    Not.new(self)
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
# def some(e)
#   Exists.new(e)
# end

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

class ForAll < Formula
  # v: quantified variable name (String)
  # t: type expression (Expr)
  # f: quantified formula (Formula)
  def initialize(v, t, f)
    @var = v
    @typ = t
    @formula = f
  end
  def to_s
    "ForAll(#{@var}:#{@typ.to_s},#{@formula.to_s})"
  end
  def to_alloy(ctx=nil)
    enclose("all #{@var} : #{@typ.to_alloy(ctx)} | #{@formula.to_alloy(ctx)}")
  end
  def rewrite(ctx)
    ForAll.new(@var, @typ.rewrite(ctx), @formula.rewrite(ctx))
  end
end
def forall(v, t, f)
  ForAll.new(v, t, f)
end

class Exist < Formula
  # v: quantified variable name (String)
  # t: type expression (Expr)
  # f: quantified formula (Formula)
  def initialize(v, t, f)
    @var = v
    @typ = t
    @formula = f
  end
  def to_s
    "Exist(#{@var}:#{@typ.to_s},#{@formula.to_s})"
  end
  def to_alloy(ctx=nil)
    enclose("some #{@var} : #{@typ.to_alloy(ctx)} | #{@formula.to_alloy(ctx)}")
  end
  def rewrite(ctx)
    Exist.new(@var, @typ.rewrite(ctx), @formula.rewrite(ctx))
  end
end
def exists(v, t, f)
  Exist.new(v, t, f)
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
  return Unit.new if fs.empty?
  fs[1..-1].inject(fs[0]) { |r, e| And.new(r, e) }
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
def disjs(fs)
  return Unit.new if fs.empty?
  fs[1..-1].inject(fs[0]) { |r, e| Or.new(r, e) }
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
