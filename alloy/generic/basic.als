module basic

// no fields
// with partially ordered event traces
open util/ordering[Op] as OO

/** FOR VIZ ONLY **/
open util/ordering[Step] as SO
sig Step {
	o : one Op
}
fact {
	all disj s1, s2 : Step |
		s1 -> s2 in SO/next implies s1.o -> s2.o in OO/next
}
/********************/

/**
	* Generic part of the model
	*/
abstract sig Data {}
abstract sig Module {
	creates : set Data,
	accesses : Data -> Op
}{
	all d : Data,  o : Op |
		-- can only access a piece of data "d" right before "o" takes places only if
		d in accesses.o implies {
			-- (1) it creates the data itself or
			d in creates or
			-- (2) it has already received the data from a previous op
			some o2 : SuccessOp & (o.prevs) {
				(this = o2.sender and d in o2.ret) or
				(this = o2.receiver and d in o2.args)
			}
		}
}

fun initAccess[m : Module] : set Data {
	m.creates
}

/**
	* Operations
	*/

-- an operation is successful iff its receiver accepts it
fun SuccessOp : set Op {
	receiver.Module
}

abstract sig Op {
	sender : Module,
	receiver : lone Module,
	args : set Data,
	ret : set Data
}{
	receiver != sender
	(args) in sender.accesses.this
	(ret) in receiver.accesses.this + args
}

fun receives[m : Module, es : set Op] : set Op {
	receiver.m & es
}

fun sends[m : Module, es : set Op]  : set Op {
	sender.m & es
}

fun arg[d : Data] : set Data {
	d
}

fun hasReceived[m : Module, o : Op, typ : set Op] : Op {
	m.receives[typ] & prevs[o] & SuccessOp
}

fun hasSent[m : Module, o : Op, typ : set Op] : Op {
	m.sends[typ] & prevs[o] & SuccessOp
}

sig NonCriticalData in Data {}

sig GoodData, BadData in Data {}
fact DataFacts {
	no GoodData & BadData
	creates.GoodData in TrustedModule
	creates.BadData in UntrustedModule
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

pred mayAccess[m : Module, d : Data] {
		d in m.accesses.Op
}

pred Confidentiality {
	no m : UntrustedModule, d : GoodData |
		mayAccess[m, d]
}

pred Integrity {
	no m : ProtectedModule, d : BadData |
		mayAccess[m, d]
}

run {} for 3
