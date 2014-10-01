require 'nokogiri'

SPECIAL_DATA_ON = true

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

def convert_field(cmp, fld, root)
  tuples = []
  type = fld.xpath("types")[0]
  arity = type.elements.size
  types = []

  (1..(arity - 1)).each do |i|
    t = type.elements[i]
    sig = root.xpath(".//sig[@ID=#{t["ID"]}]")[0]
    types[i - 1] = clean_label(sig)
  end

  join(cmp, fld).each do |t|
    tuple = Hash.new
    # ignore the first column, hence start from 1
    (1..(arity - 1)).each do |i|
      tuple[types[i - 1]] = clean_label(t.elements[i])
    end
    tuples.push(tuple)
  end
  [clean_label(fld), types, tuples]
end

def convert_cmp(cmp, root)
  cmptypes = sigs_with_atom(cmp, root)
  cmptype = filter_top_level(cmptypes)
  trusted = cmptypes.select {|c| clean_label(c) == "TrustedModule"}.any?

  # extract field IDs
  cmp_id = cmptype["ID"]
  rel_fields = root.xpath(".//field[@parentID=#{cmp_id}]")
  fields = Hash.new

  rel_fields.each do |f|
    flabel, types, tuples = convert_field(cmp, f, root)
    fields[flabel] = [types, tuples]
  end

  [{:inst => clean_label(cmp),
    :type => clean_label(cmptype),
    :trusted => trusted}, fields]
end

def convert_data_tuples(tuples, root, datatypes)
  tuples.map {|t|
    element = t.elements[1]
    l = clean_label(element)
    if (not already_added(datatypes, l))
      datatypes.push(convert_data(element, root))
    end
    l }
end

def convert_data(datum, root)
  datatypes = sigs_with_atom(datum, root)
  datatype = filter_top_level(datatypes)
  {:inst => clean_label(datum),
    :type => clean_label(datatype)}
end

def parse_events root
  sig_ops = root.xpath(".//sig[@label='webbasic/basic/Op']")[0]
  rel_sender = root.xpath(".//field[@label='sender']")[0]
  rel_receiver = root.xpath(".//field[@label='receiver']")[0]
  rel_args = root.xpath(".//field[@label='args']")[0]
  rel_ret = root.xpath(".//field[@label='ret']")[0]

  # arrays of hashes to be sent back to the client
  events = []
  data = []
  cmps = []
  cmp_fields = Hash.new
  
  num_ops = sig_ops.elements.length

  sig_ops.elements.each do |op|
    # Ignore the last operation
    # TODO: A better way to do this?
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
    strlist_args = convert_data_tuples(tuples_args, root, data)

    # returns
    strlist_rets = convert_data_tuples(tuples_rets, root, data)
    
    # add component if not already added
    if not already_added(cmps, clean_label(sender))
      cmp, fields = convert_cmp(sender, root)
      cmps.push(cmp)
      cmp_fields[cmp[:inst]] = fields
    end 
    if not already_added(cmps, clean_label(receiver))
      cmp, fields = convert_cmp(receiver, root)
      cmps.push(cmp)
      cmp_fields[cmp[:inst]] = fields
    end

    # create a new event instance
    events.push({:inst => clean_label(op),
                  :sender => clean_label(sender),                  
                  :receiver => clean_label(receiver),
                  :type => clean_label(optype),
                  :args => strlist_args,
                  :ret => strlist_rets})
  end
  
  [data, cmps, cmp_fields, events]
end

def parse_accesses root  
  rel_accesses = root.xpath(".//field[@label='accesses']")[0]
  accesses = []

  rel_accesses.xpath("tuple").each do |a|
    cmp_atom = a.elements[0]
    data_atom = a.elements[1]
    op_atom = a.elements[2]
    accesses.push({:cmp => clean_label(cmp_atom),
                    :op => clean_label(op_atom),
                    :data => clean_label(data_atom)})
  end
  
  accesses
end

def parse_alloy_instance inst_fname
  puts "@@@@@@@@@@@@@"
  puts "Parsing Alloy instance"
  f = File.open(inst_fname, 'r')
  root = Nokogiri::XML(f)
  f.close

  structures = parse_events root
  data = structures[0]
  cmps = structures[1]
  cmp_fields = structures[2]
  events = structures[3]
  accesses = parse_accesses root

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

  {:cmps => cmps, :data => data, :events => events, 
    :fields => cmp_fields,
    :accesses => accesses,
    :specialData => special_data}
end

