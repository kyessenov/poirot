# alloy_printer.rb
#
# For printing Alloy model from a Slang model
#

require 'pp'

# helpful constants
DOT_FILE = "out.dot"
ALLOY_FILE = "out.als"
FONTNAME = "helvetica"
UNIT = "UNIT"
SUPER_COLOR="gold"
CHILD_COLOR="beige"
STEP_TYPE = :Step

def mkScopeSpec v
  scopes = v.calcScopes
  default_scope = Options.optVal(:DEFAULT_SCOPE)
  if (not v.isDynamic) && Options.isOptOn(:OPT_TIMELESS) then
    "#{default_scope} but #{scopes[:Data]} Data, " + 
      "#{scopes[:Op]} Op, #{scopes[:Module]} Module\n"
  else 
    "#{default_scope} but #{scopes[:Data]} Data, #{scopes[:Op] + 1} Step," + 
      "#{scopes[:Op]} Op, #{scopes[:Module]} Module\n"
  end
end

def mkPropertyCmds v
    cmdStr =
"
check Confidentiality {
  Confidentiality
} for #{mkScopeSpec v}

-- check who can create CriticalData
check Integrity {
  Integrity
} for #{mkScopeSpec v}"

  if v.isDynamic || (not Options.isOptOn(:OPT_TIMELESS)) then
    cmdStr += 
"
fun RelevantOp : Op -> Step {
  {o : Op, t : Step | o.pre = t and o in SuccessOp}
}"
  end

  cmdStr
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

def dotModule (m, color=nil)
  if m.extends.empty?
    "#{m.name} [shape=component,style=\"filled\",color=\"#{color}\"];"
  else
    "#{m.name}_#{m.extends[0].name} [shape=component," +
      "label=\n" +
      "<<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\">\n" +
      "<TR><TD BGCOLOR=\"#{color}\">#{m.name}</TD></TR>\n" +
      "<TR><TD BGCOLOR=\"#{SUPER_COLOR}\">#{m.extends[0].name}</TD></TR>\n" +
      "</TABLE>>];\n"
  end
end

def dotOpName(mname, opname)
  "#{mname}_#{opname}"
end

def dotOp(mname, opname, o, color=nil)
  abridged = "#{o.name}"[o.name.to_s.index("__") + 2..-1]
  if not o.parent
    "#{dotOpName(mname, opname)} [label=\"#{abridged}\",shape=rectangle,fillcolor=\"#{color}\",style=\"filled,rounded\"];"
  else
    parentAbridged = "#{o.parent.name}"[o.parent.name.to_s.index("__") + 2..-1]
    "#{dotOpName(mname, opname)} [shape=rectangle,style=\"rounded\"," +
      "label=\n" +
      "<<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\">\n" +
      "<TR><TD BGCOLOR=\"#{color}\">#{abridged}</TD></TR>\n" +
      "<TR><TD BGCOLOR=\"#{SUPER_COLOR}\">#{parentAbridged}</TD></TR>\n" +
      "</TABLE>>];\n"
  end
end

def mkModname m
  if m.extends.empty?
    "#{m.name}"
  else
    "#{m.name}_#{m.extends[0].name}"
  end
end

def writeDot(view, dotFile, color=CHILD_COLOR)
  mods = view.modules
  f = File.new(dotFile, 'w')
  f.puts "digraph g {"
  f.puts 'graph[fontname="' + FONTNAME + '", splines=true, concentrate=true];'
  f.puts 'node[fontname="' + FONTNAME + '"];'
  f.puts 'edge[fontname="' + FONTNAME + '", len=1.0];'

  # type: sym -> list str
  modnames = {}
  mods.each do |m|
    if m.isAbstract
      next
    end
    if not m.extends.empty?
      parent = m.extends[0].name
      n = "#{m.name}_#{m.extends[0].name}"
      modnames[m.name] = [n]
      if not modnames[parent] then modnames[parent] = [] end
      modnames[parent] << n
    else
      modnames[m.name] = [m.name.to_s]
    end
  end

  # type: sym -> list str
  opnames = {}
  mods.each do |m|
    m.exports.each do |e|
      if e.isAbstract
        next
      end
      if e.parent
        pname = e.parent.name
        ename = "#{e.name}_#{pname}"
        opnames[e.name] = [ename]
        if not opnames[pname] then opnames[pname] = [] end
        opnames[pname] << ename
      else
        opnames[e.name] = [e.name.to_s]
      end
    end
  end

  mods.each do |m|
    # if m.extends and not m.extends.empty?
    #   puts "#{m.name} extends #{m.extends[0].name}"
    # else
    #   puts m.name
    # end
    if m.isAbstract
      next
    end
    mname = modnames[m.name][0]

    # draw incoming connections
    f.puts "subgraph cluster_#{m.name} { "
    f.puts "style=filled; color=lightgrey;"
    f.puts(dotModule(m, color))
    m.exports.each do |e|
      opnames[e.name].each do |opname|
        f.puts(dotOp(mname, opname, e, color))
        f.puts("#{mname} -> #{dotOpName(mname, opname)} [style=dashed,dir=none];")
      end
    end

    # draw incoming connections for module that m extends, if any
    if not m.extends.empty?
      parent = m.extends[0]
      parent.exports.each do |e|
        if not e.isAbstract
          opnames[e.name].each do |opname|
            f.puts(dotOp(mname, opname, e, SUPER_COLOR))
            f.puts("#{mname} -> #{dotOpName(mname, opname)}" +
                   " [style=dashed,dir=none];")
          end
        end
      end
    end
    f.puts "}"

    # draw outgoing connections
    m.invokes.each do |i|
      mods.each do |m2|
        if m2.exports.any? { |i2| i2.name == i.name}
          opnames[i.name].each do |opname|
            m2name = modnames[m2.name][0]
            f.puts("#{mname} -> #{dotOpName(m2name, opname)};")
          end
        end
      end
    end
    # draw outgoing connections for module that m extends
    if not m.extends.empty?
      parent = m.extends[0]
      parent.invokes.each do |i|
        mods.each do |m2|
          if m2.exports.any? { |i2| i2.name == i.name}
            opnames[i.name].each do |opname|
              modnames[m2.name].each do |m2name|
                f.puts("#{mname} -> #{dotOpName(m2name, opname)};")
              end
            end
          end
        end
      end
    end
  end
  
  # draw data elements
  if Options.isOptOn(:DRAW_DATATYPES)
    view.data.each do |d|
      f.puts("#{d.name}[shape=ellipse,style=\"filled\",color=\"greenyellow\"];")
    end
  end

  f.puts "}"
  f.close
end

def mkAlloyCmds v
  (mkSanityCheck v) + "\n" + (mkPropertyCmds v) 
end

def mkSanityCheck v
  sanityCheck = "run SanityCheck {\n"
  v.modules.each do |m|
    m.exports.each do |o|
      sanityCheck += "  some #{o.name} & SuccessOp\n"
    end
  end
  sanityCheck += "} for " + (mkScopeSpec v)
end

def dumpAlloy(v, alloyFile = ALLOY_FILE)
  f = File.new(alloyFile, 'w')
  # headers
  f.puts "open generic/basic"
  f.puts
  f.puts v.to_alloy
  # footers
  f.puts
  f.puts mkAlloyCmds(v)
  f.close
end

def drawView(v, dotFile=DOT_FILE, color=CHILD_COLOR)
  writeDot v, dotFile, color
end
