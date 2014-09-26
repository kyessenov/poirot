$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../alloy_ruby/lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../sdg_utils/lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../arby/lib', __FILE__)

require 'sdsl/myutils'
require 'pry'
require 'nokogiri'

SPECIAL_DATA_ON = true
MAX_TRACE_LENGTH = 7

SLANG_PREFIX =
"
require 'slang/slang_dsl'

include Slang::Dsl
Component = Slang::Model::Module
AllData = Slang::Model::Data

Slang::Dsl.view :PoirotModel do
"

SLANG_SUFFIX =
"
  component EvilServer {
    typeOf HttpServer
    op EvilHttpReq[in: (set AllData), ret: AllData] 
  }

  component EvilClient {
    typeOf Browser
  }
end
"

DEFAULT_MODEL_PATH = "generated/poirot/poirotmodel.rb"
DEFAULT_MODEL_NAME = "PoirotModel"
DEFAULT_INST_PATH = "generated/poirot/inst.rb"

ALLOY_JAR_NAME = "generated/alloy/CmdAlloy.jar"
DEFAULT_ALLOY_INST = "generated/alloy/out.xml"
JNI_PATH = "generated/alloy/libjni"

def pad_model model
  SLANG_PREFIX + model + SLANG_SUFFIX  
end

def label(atom)
    return atom['label']
end

def join(atom, rel)
  l = label(atom)
  rel.xpath('tuple').select {|t| label(t.elements[0]) == l}
end

def clean_label(obj)
  label(obj).split("/")[-1].split("__")[-1].tr('$','')
end

def already_added(objs, inst_name)
  objs.select {|o| o[:inst] == inst_name }.any?
end

def filter_top_level(types)
  top_types = types.select{|s| label(s).start_with? "this/"}    
  if (not top_types.empty?) 
    top_types[0]
  else
    types[-1]
  end  
end

def sigs_with_atom(atom, root)
  sigs = []
  root.xpath('.//sig').each do |s|
    s.xpath('atom').each do |a|
      if (label(a) == label(atom))
        sigs.push(s)
      end
    end
  end  
  sigs
end

def convert_cmp(cmp, root)
  cmptypes = sigs_with_atom(cmp, root)
  cmptype = filter_top_level(cmptypes)
  trusted = cmptypes.select {|c| clean_label(c) == "TrustedModule"}.any?

  {:inst => clean_label(cmp),
    :type => clean_label(cmptype),
    :trusted => trusted}
end

def convert_data(datum, root)
  datatypes = sigs_with_atom(datum, root)
  datatype = filter_top_level(datatypes)
  {:inst => clean_label(datum),
    :type => clean_label(datatype)}
end

def parse_alloy_instance 
  puts "@@@@@@@@@@@@@"
  puts "Parsing Alloy instance"
  f = File.open(DEFAULT_ALLOY_INST, 'r')
  root = Nokogiri::XML(f)
  f.close
  sig_ops = root.xpath(".//sig[@label='WebBasic/basic/Op']")[0]
  rel_sender = root.xpath(".//field[@label='sender']")[0]
  rel_receiver = root.xpath(".//field[@label='receiver']")[0]
  rel_args = root.xpath(".//field[@label='args']")[0]
  rel_ret = root.xpath(".//field[@label='ret']")[0]
  rel_accesses = root.xpath(".//field[@label='accesses']")[0]

  # arrays of hashes to be sent back to the client
  events = []
  data = []
  cmps = []
  accesses = []

  num_ops = sig_ops.elements.length

  sig_ops.elements.each do |op|
    if op["label"].end_with?("Op$#{num_ops - 1}")
      break;
    end
    # get tuples that are relevant to this op
    tuples_sender = join(op, rel_sender)
    tuples_receiver = join(op, rel_receiver)
    tuples_rets = join(op, rel_ret)
    tuples_args = join(op, rel_args)

    # Sender of operation
    sender = tuples_sender[0].elements[1]
    # Receiver of operation
    receiver = tuples_receiver[0].elements[1]
    # Operation types
    optype = filter_top_level(sigs_with_atom(op, root))
    
    # arguments
    strlist_args = 
      tuples_args.map {|t|
        datum = t.elements[1]
        l = clean_label(datum)
        if (not already_added(data, l))
          data.push(convert_data(datum, root))
        end
        l }

    # returns
    strlist_rets = 
      tuples_rets.map {|t|
        datum = t.elements[1]
        l = clean_label(datum)
        if (not already_added(data, l))
          data.push(convert_data(datum, root))
        end
        l }
    
    # create a new event instance
    events.push({
                  :inst => clean_label(op),
                  :sender => clean_label(sender),                  
                  :receiver => clean_label(receiver),
                  :type => clean_label(optype),
                  :args => strlist_args,
                  :ret => strlist_rets})
    # add component if not already added
    if (not already_added(cmps, clean_label(sender)))
      cmps.push(convert_cmp(sender, root))
    end
    if (not already_added(cmps, clean_label(receiver)))
      cmps.push(convert_cmp(receiver, root))
    end
  end 

  rel_accesses.xpath("tuple").each do |a|
    cmp_atom = a.elements[0]
    data_atom = a.elements[1]
    op_atom = a.elements[2]
    accesses.push({
                    :cmp => clean_label(cmp_atom),
                    :op => clean_label(op_atom),
                    :data => clean_label(data_atom)})
  end

  special_data = {}
  if (SPECIAL_DATA_ON) 
    tupleMyId = root.xpath(".//field[@label='Customer__myId']")[0].elements[0]
    tupleMyPwd = root.xpath(".//field[@label='Customer__myPwd']")[0].elements[0]
    tuplesSessions = root.xpath(".//field[@label='MyStore__sessions']")[0].xpath("tuple")
    tuplesPasswords = root.xpath(".//field[@label='MyStore__passwords']")[0].xpath("tuple")
    tuplesOrders = root.xpath(".//field[@label='MyStore__orders']")[0].xpath("tuple")
    
    special_data[:myId] = clean_label(tupleMyId.elements[1]);
    special_data[:myPwd] = clean_label(tupleMyPwd.elements[1]);
    special_data[:passwords] = []
    special_data[:sessions] = []
    special_data[:orders] = []

    tuplesSessions.each do |t|
      special_data[:sessions].push(:uid => clean_label(t.elements[1]),
                                   :sid => clean_label(t.elements[2]),
                                   :op => clean_label(t.elements[3]))
    end
    tuplesPasswords.each do |t|
      special_data[:passwords].push(:uid => clean_label(t.elements[1]),
                                    :pwd => clean_label(t.elements[2]),
                                    :op => clean_label(t.elements[3]))
    end
    tuplesOrders.each do |t|
      special_data[:orders].push(:uid => clean_label(t.elements[1]),
                                 :oid => clean_label(t.elements[2]),
                                 :op => clean_label(t.elements[3]))
    end
  end

  {:cmps => cmps, :data => data, :events => events, :accesses => accesses,
  :specialData => special_data}
end

def run_alloy(alloy_file, cmd)
  puts "%%%%%%%%%%%%%%%"
  puts "Running alloy"
  if (cmd == "SanityCheck") 
    system "java -jar -Djava.library.path=#{JNI_PATH} #{ALLOY_JAR_NAME} #{alloy_file} #{cmd}"
  else 
    system "java -jar -Djava.library.path=#{JNI_PATH} #{ALLOY_JAR_NAME} #{alloy_file} myRequirement #{MAX_TRACE_LENGTH}"    
  end
  system "mv out.xml #{DEFAULT_ALLOY_INST}"
  puts "%%%%%%%%%%%%%%%"
end

def run_poirot(cmd, fname=DEFAULT_MODEL_PATH, model_name=DEFAULT_MODEL_NAME)
  puts "##########"
  fail "Cannt load `#{fname}'" unless load fname
  view = (eval(model_name) rescue nil)

  fail "Model not found: #{model_name}" unless view
  out_file ||= "generated/alloy/#{model_name.downcase}.als"
  dot_out_file ||= "generated/alloy/#{model_name.downcase}.dot"

  # sdsl_view = view.meta.to_sdsl
  sdsl_view = view.meta.to_poirot_sdsl
  drawView(sdsl_view, dot_out_file)
  dumpAlloy(sdsl_view, out_file)
  
  puts "Alloy file saved in #{out_file}"
  puts "##########"
  
  run_alloy(out_file, cmd)
  parse_alloy_instance
end

