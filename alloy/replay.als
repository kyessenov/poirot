open models/basic
open models/crypto[Data]

-- module EndPoint
sig EndPoint extends Module {
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
	TrustedModule = EndPoint + Channel + Eavesdropper
}

-- operation EndPoint__Deliver
sig EndPoint__Deliver extends Op {
	EndPoint__Deliver__packets : set Packet,
}{
	args = EndPoint__Deliver__packets
	sender in Channel
	receiver in EndPoint
}

-- operation Channel__Transmit
sig Channel__Transmit extends Op {
	Channel__Transmit__packets : set Packet,
}{
	args = Channel__Transmit__packets
	sender in EndPoint
	receiver in Channel
}

-- operation Channel__Probe
sig Channel__Probe extends Op {
	Channel__Probe__packets : set Packet,
}{
	args = Channel__Probe__packets
	sender in Eavesdropper
	receiver in Channel
}

-- operation Eavesdropper__Emit
sig Eavesdropper__Emit extends Op {
	Eavesdropper__Emit__packets : set Packet,
}{
	args = Eavesdropper__Emit__packets
	sender in Channel
	receiver in Eavesdropper
}

-- fact dataFacts
fact dataFacts {
	creates.Packet in EndPoint
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
