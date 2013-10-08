open models/basic
open models/crypto[Data]

-- module EndpointA
one sig EndpointA extends Module {
}
-- module EndpointB
one sig EndpointB extends Module {
}
-- module Channel
one sig Channel extends Module {
}{
	all o : this.sends[Eavesdropper__Emit] | triggeredBy[o,Channel__Probe]
}

-- module Eavesdropper
one sig Eavesdropper extends Module {
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
	sender in Channel
	receiver in EndpointA
}

-- operation EndpointB__DeliverB
sig EndpointB__DeliverB extends Op {
	EndpointB__DeliverB__data : set Packet,
}{
	args = EndpointB__DeliverB__data
	sender in Channel
	receiver in EndpointB
}

-- operation Channel__Transmit
sig Channel__Transmit extends Op {
	Channel__Transmit__data : set Packet,
}{
	args = Channel__Transmit__data
	sender in EndpointA + EndpointB
	receiver in Channel
}

-- operation Channel__Probe
sig Channel__Probe extends Op {
	Channel__Probe__data : set Packet,
}{
	args = Channel__Probe__data
	sender in Eavesdropper
	receiver in Channel
}

-- operation Eavesdropper__Emit
sig Eavesdropper__Emit extends Op {
	Eavesdropper__Emit__data : set Packet,
}{
	args = Eavesdropper__Emit__data
	sender in Channel
	receiver in Eavesdropper
}

-- fact dataFacts
fact dataFacts {
	creates.Packet in EndpointA + EndpointB
}

-- datatype declarations
sig Packet extends Data {
}{
	no fields
}
sig OtherData extends Data {}{ no fields }


fun RelevantOp : Op -> Step {
	{o : Op, t : Step | o.post = t and o in SuccessOp}
}

run SanityCheck {
	all m : Module |
		some sender.m & SuccessOp
} for 1 but 9 Data, 10 Step, 9 Op

check Confidentiality {
   Confidentiality
} for 1 but 9 Data, 10 Step, 9 Op

-- check who can create CriticalData
check Integrity {
   Integrity
} for 1 but 9 Data, 10 Step, 9 Op
