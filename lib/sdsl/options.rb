# optimizer.rb
# optimization switches

module Options 
  @@opts = { 
    :OPT_TIMELESS => true, :OPT_GLOBAL_DATA => true, 
    :DEFAULT_SCOPE => 1,
    :DRAW_DATATYPES => true
  }

  def self.setOpt (s, b)
    @@opts[s] = b
  end
  
  def self.optVal s
    return @@opts[s]
  end

  def self.isOptOn s
    return (@@opts[s] == true)
  end
end
