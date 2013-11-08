open models/basic
open models/crypto[Data]

-- module EndPoint
sig EndPoint extends Module {
}{
	accesses.first in NonCriticalData + Packet
}

-- module Channel
one sig Channel extends Module {
}{
	all o : this.sends[Eavesdropper__Emit] | triggeredBy[o,Channel__Probe]
	accesses.first in NonCriticalData
}

-- module Eavesdropper
one sig Eavesdropper extends Module {
}{
	accesses.first in NonCriticalData
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = EndPoint + Channel + Eavesdropper
}

-- operation EndPoint__Deliver
sig EndPoint__Deliver extends Op {
	EndPoint__Deliver__packets : set Packet,
}{
	args = EndPoint__Deliver__packets
	no ret
	sender in Channel
	receiver in EndPoint
}

-- operation Channel__Transmit
sig Channel__Transmit extends Op {
	Channel__Transmit__packets : set Packet,
}{
	args = Channel__Transmit__packets
	no ret
	sender in EndPoint
	receiver in Channel
}

-- operation Channel__Probe
sig Channel__Probe extends Op {
	Channel__Probe__packets : set Packet,
}{
	args = Channel__Probe__packets
	no ret
	sender in Eavesdropper
	receiver in Channel
}

-- operation Eavesdropper__Emit
sig Eavesdropper__Emit extends Op {
	Eavesdropper__Emit__packets : set Packet,
}{
	args = Eavesdropper__Emit__packets
	no ret
	sender in Channel
	receiver in Eavesdropper
}

-- datatype declarations
sig Packet extends Data {
}{
	no fields
}
sig OtherData extends Data {}{ no fields }

run SanityCheck {
  some EndPoint__Deliver & SuccessOp
  some Channel__Transmit & SuccessOp
  some Channel__Probe & SuccessOp
  some Eavesdropper__Emit & SuccessOp
} for 1 but 7 Data, 7 Step, 6 Op

fun RelevantOp : Op -> Step {
  {o : Op, t : Step | o.post = t and o in SuccessOp}
}
check Confidentiality {
  Confidentiality
} for 1 but 7 Data, 7 Step, 6 Op

-- check who can create CriticalData
check Integrity {
  Integrity
} for 1 but 7 Data, 7 Step, 6 Op
