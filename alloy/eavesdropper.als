open models/basic
open models/crypto[Data]

-- module EndpointA
one sig EndpointA extends Module {
}{
	accesses.first in NonCriticalData + Packet
}

-- module EndpointB
one sig EndpointB extends Module {
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
	TrustedModule = EndpointA + EndpointB + Channel + Eavesdropper
}

-- operation EndpointA__DeliverA
sig EndpointA__DeliverA extends Op {
	EndpointA__DeliverA__data : set Packet,
}{
	args = EndpointA__DeliverA__data
	no ret
	sender in Channel
	receiver in EndpointA
}

-- operation EndpointB__DeliverB
sig EndpointB__DeliverB extends Op {
	EndpointB__DeliverB__data : set Packet,
}{
	args = EndpointB__DeliverB__data
	no ret
	sender in Channel
	receiver in EndpointB
}

-- operation Channel__Transmit
sig Channel__Transmit extends Op {
	Channel__Transmit__data : set Packet,
}{
	args = Channel__Transmit__data
	no ret
	sender in EndpointA + EndpointB
	receiver in Channel
}

-- operation Channel__Probe
sig Channel__Probe extends Op {
	Channel__Probe__data : set Packet,
}{
	args = Channel__Probe__data
	no ret
	sender in Eavesdropper
	receiver in Channel
}

-- operation Eavesdropper__Emit
sig Eavesdropper__Emit extends Op {
	Eavesdropper__Emit__data : set Packet,
}{
	args = Eavesdropper__Emit__data
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
  some EndpointA__DeliverA & SuccessOp
  some EndpointB__DeliverB & SuccessOp
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
