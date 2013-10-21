open models/basic
open models/crypto[Data]

-- module User
one sig User extends Module {
	User__intents : set URI,
}{
	all o : this.sends[Client__Visit] | (some (User__intents & o.(Client__Visit <: Client__Visit__dest)))
	(not (some (User__intents & MaliciousServer.MaliciousServer__addr)))
}

-- module TrustedServer
one sig TrustedServer extends Module {
	TrustedServer__addr : lone URI,
}{
	all o : this.sends[Client__HttpResp] | triggeredBy[o,TrustedServer__HttpReq]
}

-- module MaliciousServer
one sig MaliciousServer extends Module {
	MaliciousServer__addr : lone URI,
}
-- module Client
one sig Client extends Module {
}{
	all o : this.sends[TrustedServer__HttpReq] | 
		((triggeredBy[o,Client__Visit] and o.(TrustedServer__HttpReq <: TrustedServer__HttpReq__addr) = o.trigger.((Client__Visit <: Client__Visit__dest)))
		or
		(triggeredBy[o,Client__HttpResp] and o.(TrustedServer__HttpReq <: TrustedServer__HttpReq__addr) = o.trigger.((Client__HttpResp <: Client__HttpResp__redirectTo)))
		)
	all o : this.sends[MaliciousServer__HttpReq] | 
		((triggeredBy[o,Client__Visit] and o.(MaliciousServer__HttpReq <: MaliciousServer__HttpReq__addr) = o.trigger.((Client__Visit <: Client__Visit__dest)))
		or
		(triggeredBy[o,Client__HttpResp] and o.(MaliciousServer__HttpReq <: MaliciousServer__HttpReq__addr) = o.trigger.((Client__HttpResp <: Client__HttpResp__redirectTo)))
		)
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = User + TrustedServer + Client
}

-- operation TrustedServer__HttpReq
sig TrustedServer__HttpReq extends Op {
	TrustedServer__HttpReq__addr : lone URI,
}{
	args = TrustedServer__HttpReq__addr
	no ret
	sender in Client
	receiver in TrustedServer
}

-- operation MaliciousServer__HttpReq
sig MaliciousServer__HttpReq extends Op {
	MaliciousServer__HttpReq__addr : lone URI,
}{
	args = MaliciousServer__HttpReq__addr
	no ret
	sender in Client
	receiver in MaliciousServer
}

-- operation Client__Visit
sig Client__Visit extends Op {
	Client__Visit__dest : lone URI,
}{
	args = Client__Visit__dest
	no ret
	sender in User
	receiver in Client
}

-- operation Client__HttpResp
sig Client__HttpResp extends Op {
	Client__HttpResp__redirectTo : lone URI,
}{
	args = Client__HttpResp__redirectTo
	no ret
	sender in TrustedServer + MaliciousServer
	receiver in Client
}

-- datatype declarations
sig URI extends Data {
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
