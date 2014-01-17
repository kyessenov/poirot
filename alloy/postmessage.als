open models/basic

-- module Script
sig Script extends Module {
	Script__origin : one Origin,
}{
	all o : this.sends[Script__PostMessage] | o.(Script__PostMessage <: Script__PostMessage__src) = Script__origin
	this.initAccess in NonCriticalData + Script__origin
}


-- operation Script__PostMessage
sig Script__PostMessage extends Op {
	Script__PostMessage__data : one Str,
	Script__PostMessage__src : one Origin,
	Script__PostMessage__dest : one Origin,
}{
	args in Script__PostMessage__data + Script__PostMessage__src + Script__PostMessage__dest
	no ret
	sender in Script
	receiver in Script
}

-- datatype declarations
abstract sig Str extends Data {
}{
	no fields
}
sig Origin {
}
sig OtherData extends Data {}{ no fields }

run SanityCheck {
  some Script__PostMessage & SuccessOp
} for 2 but 1 Data, 2 Step,1 Op, 1 Module


check Confidentiality {
  Confidentiality
} for 2 but 1 Data, 2 Step,1 Op, 1 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 1 Data, 2 Step,1 Op, 1 Module

fun RelevantOp : Op -> Step {
  {o : Op, t : Step | o.pre = t and o in SuccessOp}
}
