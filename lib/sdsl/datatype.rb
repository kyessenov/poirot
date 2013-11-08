# data.rb
#
require 'rubygems'
require 'docile'
require 'sdsl/myutils'

Datatype = Struct.new(:name, :fields, :extends, :isAbstract, :isSingleton)

class DatatypeBuilder
  def initialize 
    @fields = []
    @extends = :Data
    @isAbstract = false
    @isSingleton = false
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

  def setAbstract 
    @isAbstract = true
  end

  def setSingleton
    @isSingleton = true
  end

  def build name
    Datatype.new(name, @fields, @extends, @isAbstract, @isSingleton)
  end
end

class Datatype
  def to_alloy(ctx=nil)
    alloyChunk = ""
    
    if isAbstract then alloyChunk += "abstract " end
    if isSingleton then alloyChunk += "one " end

    alloyChunk += wrap("sig #{name} extends #{extends} {")
    fields.each do |f|
      alloyChunk += wrap(f.to_alloy(ctx) + ",", 1)
    end
    alloyChunk += wrap("}{")    
    if fields.empty?
      if not isAbstract then alloyChunk += wrap("no fields", 1) end
    else 
      alloyChunk += wrap("fields = " + fields.map{ |f| f.name }.join(" + "), 1)
    end
    alloyChunk += wrap("}")
  end
end

def datatype(name, &block)
  Docile.dsl_eval(DatatypeBuilder.new, &block).build name
end
