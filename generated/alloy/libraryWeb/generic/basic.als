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
	ret : set Data,
 	trigger : lone Op
}{
	receiver != sender
	(args) in sender.accesses.this
	(ret) in receiver.accesses.this + args

	some trigger implies {
		trigger in this.prevs
		sender in trigger.@receiver + trigger.@sender
	}
}

pred triggeredBy[o : Op, trigType : set Op] {
	o.trigger in trigType
}

pred disjointOps[o1 : set Op, o2: set Op] {
	no o1 & o2
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

sig CriticalData, NonCriticalData in Data {}
sig BadData in Data {}
sig ConfidentialData in Data {}
fact DataFacts {     
	no CriticalData & NonCriticalData
	Data = CriticalData + NonCriticalData
	ConfidentialData in CriticalData

	creates.BadData in UntrustedModule
}
sig TrustedModule, UntrustedModule in Module {}
sig ProtectedModule in Module {}
fact {
	Module = TrustedModule + UntrustedModule
	no TrustedModule & UntrustedModule
	ProtectedModule in TrustedModule
}

pred isTrusted[m: Module] {
	m in TrustedModule
}

/**
	* generic security properties
	*/

pred mayAccess[m : Module, d : Data] {
		d in m.accesses.Op
}

pred contains[rel : Data -> Data, col1 : Module -> Data, col2: Module -> Data] {
	let c1 = Module.col1, c2 = Module.col2 |
		c1 -> c2 in rel
}

pred uniqueAssignments[rel : Data -> Data] {
	no disj d1, d2 : Data |
		some rel[d1] & rel[d2]
}

pred confidential[rel : Module -> Data -> Data, col : Module -> Data] {
   	let r = Module.rel, c = Module.col, data = r[c] |
		data in ConfidentialData implies
			(no m : UntrustedModule, d : data |	mayAccess[m, d])
}

pred Confidentiality {
	no m : UntrustedModule, d : ConfidentialData |
		mayAccess[m, d]
}

pred Integrity {
	no m : ProtectedModule, d : BadData |
		mayAccess[m, d]
}

run {} for 3
