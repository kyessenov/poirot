module basicNoStep

/**
	* Generic part of the model
	*/
abstract sig Data {
	fields : set Data
}
abstract sig Module {
	accesses : set (Data),
	creates : set (Data)
}{
	all d : Data |
		-- can only access a data at time step t if
		d in accesses implies {
			-- (1) it already has access to date at time (t-1) or
--			(t not in SO/first and d in accesses.(t.prev)) or
			-- (2) it creates the data itself or
--			(t in SO/first and d in accesses.t) or
			d in creates or
			-- (3) another module calls operation on this and send the data as an argument
			some m2 : Module - this | flows[m2, this, d]
		}
}

pred flows[from, to : Module, d : Data] {
	(some o : SuccessOp {
		({from = o.sender and to = o.receiver and d in (o.args + o.args.^fields)} or
		{from = o.receiver and to = o.sender and d in (o.ret + o.ret.^fields)})
	})
}

/**
	* Operations
	*/

-- an operation is successful iff its receiver accepts it
fun SuccessOp : set Op {
	receiver.Module
}

abstract sig Op {
	trigger : lone Op,
	sender : Module,
	receiver : lone Module,
	args : set (Data),
	ret : set (Data)
}{
	(args + args.^fields) in sender.accesses
	(ret + ret.^fields) in receiver.accesses
	some trigger implies {
		trigger.@receiver = sender
	}
}
fun receives[m : Module, es : set Op] : set Op {
	receiver.m & es
}

fun sends[m : Module, es : set Op]  : set Op {
	sender.m & es
}


-- some helper predicates/functions
pred triggeredBy[o : Op, t : set Op] {
	some o.trigger & t
}
fun arg[d : Data] : set Data {
//	d + d.^fields
	d
}

fun originates[d : Data] : set Module {
	(creates).d
}

fun initAccess[m : Module] : set Data {
	m.creates
}

sig CriticalData in Data {}
fun NonCriticalData : set Data { Data - CriticalData }
sig GoodData, BadData in CriticalData {}
fact DataFacts {
	no GoodData & BadData
	CriticalData = GoodData + BadData
	originates[GoodData] in TrustedModule
	originates[BadData] in UntrustedModule
}
sig TrustedModule, UntrustedModule in Module {}
sig ProtectedModule in Module {}
fact {
	Module = TrustedModule + UntrustedModule
	no TrustedModule & UntrustedModule
	ProtectedModule in TrustedModule
}

/**
	* generic security properties
	*/
pred Confidentiality {
	no m : UntrustedModule |
		some m.accesses & GoodData
}

pred Integrity {
	no m : ProtectedModule |
		some m.accesses & BadData
}

run {} for 3

