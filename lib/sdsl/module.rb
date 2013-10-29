# mod.rb
# TODO: Data
#
require 'rubygems'
require 'docile'
require 'sdsl/myutils'
require 'sdsl/datatype'

Mod = Struct.new(:name, :exports, :invokes, :assumptions, 
                 :stores, :creates,
                 :extends, :isAbstract, :isUniq,
                 :dynamics)
Op = Struct.new(:name, :constraints, :parent, :child, :isAbstract)

class Mod

  def findExport n
    (exports.select { |e| e.name == n })[0]
  end

  def findInvoke n    
    (invokes.select { |i| i.name == n})[0]
  end

  def deepclone 
    Mod.new(self.name, self.exports.deepclone, self.invokes.deepclone,
            self.assumptions.clone, self.stores.clone, 
            self.creates.clone, self.extends.clone, 
            self.isAbstract, self.isUniq, self.dynamics.clone)
  end

  def setAbstract
    self.isAbstract = true
  end

  def isDynamic field
    dynamics.map{|e| "#{name}__#{e}"}.include? field.name
  end

  def rel2Set r
    rname = "#{r.name}"
    if isDynamic r
      rname = "(#{r.name}.first)"
    end
    if r.is_a? UnaryRel
      "#{rname}" 
    elsif r.is_a? Map
      "#{r.type1}.#{rname} + #{rname}.#{r.type2}"
    else
      raise "Can't convert rel #{r.to_alloy} to sets"
    end
  end

  def to_alloy(ctx)
    # (s1, s2) in decls => sig s1 extends s2
    sigfacts = []
    facts = []
    fields = []
    alloyChunk = ""

    modn = name.to_s    
    # module declaration
    fields = stores

    ctx[:nesting] = 1
    exports.each do |o|
      n = o.name
      ctx[:op] = n
      # receiver constraint
      # export constraint
      o.constraints[:when].each do |c|
        f = "all o : this.receives[" + n.to_s + "] | " + c.to_alloy(ctx)
        sigfacts << f        
      end
    end
 
    invokes.each do |o|
      n = o.name.to_s
      ctx[:op] = n
      o.constraints[:when].each do |c|
        f = "all o : this.sends[" + n + "] | " + c.to_alloy(ctx)
        sigfacts << f
      end
    end

    sigfacts += assumptions.map {|m| m.to_alloy(ctx)}

    # write Alloy expressions
    # declarations 
    alloyChunk += wrap("-- module " + modn)
    if isUniq then alloyChunk += "one " end
    if isAbstract then alloyChunk += "abstract " end

    alloyChunk += "sig " + modn + " extends "
    if not extends.empty?
      alloyChunk += wrap("#{extends[0].name} {")
    else
      alloyChunk += wrap("Module {")
    end

    # fields      
    fields.each do |f|      
      if isDynamic f
        alloyChunk += wrap(f.dynamic.to_alloy(ctx) + ",", 1)
      else
        alloyChunk += wrap(f.to_alloy(ctx) + ",", 1)
      end
    end
    alloyChunk += "}"
    # signature facts
    alloyChunk += wrap("{")
    if not sigfacts.empty? 
      sigfacts.each do |f|
        alloyChunk += wrap(f, 1)
      end
    end
    
    # initial data access
    if not (fields.empty? and creates.empty?)
      initData = []
      fields.each do |f|
          initData << (rel2Set f)
      end
      creates.each do |d|
        initData << "#{d}"
      end
      alloyChunk += wrap("accesses.first in " + initData.join(" + "), 1)
    end

    alloyChunk += wrap("}")
    # facts
    alloyChunk += writeFacts(name.to_s + "Facts", facts)
  end

end

class ModuleBuilder
  def initialize 
    @exports = []
    @invokes = []
    @assumptions = []
    @stores = []
    @creates = []
    @extends = []
    @isAbstract = false
    @isUniq = true
    @dynamics = []
  end

  def exports(op, constraints = {})   
    if constraints.empty?
      @exports << Op.new(op, {:when => [], :args => []}, nil, nil, false)
    else
      if not constraints.has_key? :args
        constraints[:args] = []
      end
      if not constraints.has_key? :when
        constraints[:when] = []
      end
      @exports << Op.new(op, constraints, nil, nil, false)
    end
  end

  def invokes(op, constraints = {})
    opnames = []
    if op.is_a? Array
      opnames = op 
    else
      opnames = [op]
    end

    opnames.each do |o|    
      if constraints.empty?
        @invokes << Op.new(o, {:when => []}, nil, nil, false)
      else 
        if not constraints.has_key? :when
          constraints[:when] = []
        end
        @invokes << Op.new(o, constraints, nil, nil, false)
      end
    end
  end

  def exports_ops(*ops) @exports += ops end
  def invokes_ops(*ops) @invokes += ops end

  def assumes(*constr)
    @assumptions += constr   
  end

  def stores (n, *types)
    if n.is_a? Rel
      obj = n
    elsif types.count == 1
      obj = Item.new(n, types[0])
    elsif types.count == 2
      obj = Map.new(n, types[0], types[1])
    else 
      raise "Invalid stores declaration"
    end

    @stores << obj
  end

  def creates(*data)    
    @creates += data
  end

  def extends parent
    @extends << parent
  end
  
  def setUniq b
    @isUniq = b
  end

  def dynamics (*fields) 
    @dynamics += fields
  end

  def build name
    Mod.new(name, @exports, @invokes, @assumptions, @stores, 
            @creates, @extends, @isAbstract, @isUniq, @dynamics)
  end
end

def mod(name, &block)
  Docile.dsl_eval(ModuleBuilder.new, &block).build name
end


