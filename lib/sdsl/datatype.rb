# data.rb
#
require 'rubygems'
require 'docile'
require 'sdsl/myutils'

SYM_BASE_DATATYPE = :Data

Datatype = Struct.new(:name, :fields, :extends, :isAbstract, :isSingleton, 
                      :types)

class DatatypeBuilder
  def initialize 
    @fields = []
    @extends = SYM_BASE_DATATYPE
    @isAbstract = false
    @isSingleton = false
    @types = []
  end

  def field f 
    @fields << f    
  end

  def fields *flds 
    @fields += flds   
  end

  def extends parent
    @extends = parent
  end

  def types *typs
    @types += typs
  end

  def setAbstract 
    @isAbstract = true
  end

  def setSingleton
    @isSingleton = true
  end

  def build name
    Datatype.new(name, @fields, @extends, @isAbstract, @isSingleton, @types)
  end
end

class Datatype
  
  # recursively grab the set of all fields of this datatype 
  # (and its ancestors, as specified by "extendsMap")
  def buildEffectiveFields extendsMap
    effectiveFields = []
    curr = self
    while curr      
      effectiveFields += curr.fields
      curr = extendsMap[curr]     
    end
    effectiveFields
  end

  def to_alloy(ctx=nil, global=false)
    alloyChunk = ""
    
    if isAbstract then alloyChunk += "abstract " end
    if isSingleton then alloyChunk += "one " end

    if global && scmp(extends, SYM_BASE_DATATYPE)
      alloyChunk += wrap("sig #{name} {")
    else 
      alloyChunk += wrap("sig #{name} extends #{extends} {")
    end
    
    fields.each do |f|
      alloyChunk += wrap(f.to_alloy(ctx) + ",", 1)
    end
    alloyChunk += ("}")
    
    # done if it's a global datatype
    if global then return alloyChunk += wrap("") end

    alloyChunk += wrap("{")
    effectiveFields = buildEffectiveFields(ctx[:extendsMap])

    isParent = ctx[:extendsMap].has_value? self
    
    field_expr = 
      (effectiveFields.empty? ? "no fields" : "fields in " + effectiveFields.map{ |f| f.name }.join(" + "))
    
    if isParent
      if not isAbstract
        childset = keysWithVal(ctx[:extendsMap], self).map {|c| c.name.to_s}.join(" + ")       
        alloyChunk += 
          wrap("this not in (#{childset}) implies " + field_expr, 1)    
      end
    else
      alloyChunk += wrap(field_expr, 1)
    end
    alloyChunk += wrap("}")
  end
  
end

def datatype(name, &block)
  Docile.dsl_eval(DatatypeBuilder.new, &block).build name
end
