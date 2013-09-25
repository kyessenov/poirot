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
Op = Struct.new(:name, :constraints, :parent, :child)

class Mod

  def findExport n
    (exports.select { |e| e.name == n })[0]
  end

  def findInvoke n    
    (invokes.select { |i| i.name == n})[0]
  end

  def deepclone 
    Mod.new(self.name, self.exports.clone, self.invokes.clone,
            self.assumptions.clone, self.stores.clone, 
            self.creates.clone, self.extends.clone, 
            self.isAbstract, self.isUniq, self.dynamics.clone)
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
      if dynamics.map{|e| "#{name}__#{e}"}.include? f.name
        alloyChunk += wrap(f.dynamic.to_alloy(ctx) + ",", 1)
      else
        alloyChunk += wrap(f.to_alloy(ctx) + ",", 1)
      end
    end
    alloyChunk += "}"
    # signature facts
    if not sigfacts.empty? 
      alloyChunk += wrap("{")
      sigfacts.each do |f|
        alloyChunk += wrap(f, 1)
      end
      alloyChunk += wrap("}")
    end

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
      @exports << Op.new(op, {:when => [], :args => []})
    else
      if not constraints.has_key? :args
        constraints[:args] = []
      end
      if not constraints.has_key? :when
        constraints[:when] = []
      end
      @exports << Op.new(op, constraints)
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
        @invokes << Op.new(o, :when => []) 
      else 
        if not constraints.has_key? :when
          constraints[:when] = []
        end
        @invokes << Op.new(o, constraints)
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


