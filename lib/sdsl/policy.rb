# policy.rb
#
require 'rubygems'
require 'docile'
require 'sdsl/myutils'

Policy = Struct.new(:name, :constr)

class PolicyBuilder
  def initialize 
    @constr = nil
  end

  def constraint c 
    @constr = c    
  end

  def build name
    Policy.new(name, @constr)
  end
end

class Policy  
  def to_alloy(ctx=nil, global=false)
    alloyChunk = wrap("pred #{name} {")
    alloyChunk += wrap(constr.to_alloy(ctx))
    alloyChunk += wrap("}")
  end
end

def policy(name, &block)
  Docile.dsl_eval(PolicyBuilder.new, &block).build name
end
