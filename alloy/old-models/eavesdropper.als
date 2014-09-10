open models/basic

-- module EndpointA
one sig EndpointA extends Module {
}{
	this.initAccess in NonCriticalData + Packet
}

-- module EndpointB
one sig EndpointB extends Module {
}{
	this.initAccess in NonCriticalData + Packet
}

-- module Channel
one sig Channel extends Module {
}{
	all o : this.sends[Eavesdropper__Emit] | triggeredBy[o,Channel__Probe]
	this.initAccess in NonCriticalData
}

-- module Eavesdropper
one sig Eavesdropper extends Module {
}{
	this.initAccess in NonCriticalData
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = EndpointA + EndpointB + Channel + Eavesdropper
}

-- operation EndpointA__DeliverA
sig EndpointA__DeliverA extends Op {
	EndpointA__DeliverA__data : set Packet,
}{
	args in EndpointA__DeliverA__data
	no ret
	sender in Channel
	receiver in EndpointA
}

-- operation EndpointB__DeliverB
sig EndpointB__DeliverB extends Op {
	EndpointB__DeliverB__data : set Packet,
}{
	args in EndpointB__DeliverB__data
	no ret
	sender in Channel
	receiver in EndpointB
}

-- operation Channel__Transmit
sig Channel__Transmit extends Op {
	Channel__Transmit__data : set Packet,
}{
	args in Channel__Transmit__data
	no ret
	sender in EndpointA + EndpointB
	receiver in Channel
}

-- operation Channel__Probe
sig Channel__Probe extends Op {
	Channel__Probe__data : set Packet,
}{
	args in Channel__Probe__data
	no ret
	sender in Eavesdropper
	receiver in Channel
}

-- operation Eavesdropper__Emit
sig Eavesdropper__Emit extends Op {
	Eavesdropper__Emit__data : set Packet,
}{
	args in Eavesdropper__Emit__data
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
} for 2 but 1 Data, 5 Op, 4 Module


check Confidentiality {
  Confidentiality
} for 2 but 1 Data, 5 Op, 4 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 1 Data, 5 Op, 4 Module
