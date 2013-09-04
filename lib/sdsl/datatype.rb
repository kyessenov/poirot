# data.rb
#
require 'rubygems'
require 'docile'
require 'myutils.rb'

Datatype = Struct.new(:name, :fields, :extends, :isAbstract)

class DataypeBuilder
  def initialize 
    @fields = []
    @extends = :Data
    @isAbstract = false
  end

  def field f 
    @fields << f    
  end

  def extends parent
    @extends = parent
  end

  def setAbstract 
    @isAbstract = true
  end

  def build name
    Datatype.new(name, @fields, @extends, @isAbstract)
  end
end

class Datatype
  def to_alloy(ctx=nil)
    alloyChunk = ""
    
    if isAbstract then alloyChunk += "abstract " end

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
  Docile.dsl_eval(DataypeBuilder.new, &block).build name
end
