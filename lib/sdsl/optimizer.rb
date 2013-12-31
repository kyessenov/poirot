# optimizer.rb
# optimization switches

module Optimizer 
  @@opts = { :TIMELESS => true, :GLOBAL_DATA => true }

  def self.setOpt (s, b)
    @@opts[s] = b
  end
  
  def self.isOptOn s
    return @@opts[s]
  end
end

