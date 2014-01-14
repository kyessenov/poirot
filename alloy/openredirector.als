open models/basicNoStep

-- module User
one sig User extends Module {
	User__intents : set URI,
}{
	all o : this.sends[Client__Visit] | (some (User__intents & o.(Client__Visit <: Client__Visit__dest)))
	(not (some (User__intents & MaliciousServer__addr)))
	this.initAccess in NonCriticalData + User__intents
}

-- module TrustedServer
one sig TrustedServer extends Module {
	TrustedServer__addr : one URI,
}{
	all o : this.sends[Client__HttpResp] | triggeredBy[o,TrustedServer__HttpReq]
	this.initAccess in NonCriticalData + TrustedServer__addr
}

-- module MaliciousServer
one sig MaliciousServer extends Module {
	MaliciousServer__addr : one URI,
}{
	this.initAccess in NonCriticalData + MaliciousServer__addr
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
	this.initAccess in NonCriticalData
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = User + TrustedServer + Client
}

-- operation TrustedServer__HttpReq
sig TrustedServer__HttpReq extends Op {
	TrustedServer__HttpReq__addr : one URI,
}{
	args in TrustedServer__HttpReq__addr
	no ret
	sender in Client
	receiver in TrustedServer
}

-- operation MaliciousServer__HttpReq
sig MaliciousServer__HttpReq extends Op {
	MaliciousServer__HttpReq__addr : one URI,
}{
	args in MaliciousServer__HttpReq__addr
	no ret
	sender in Client
	receiver in MaliciousServer
}

-- operation Client__Visit
sig Client__Visit extends Op {
	Client__Visit__dest : one URI,
}{
	args in Client__Visit__dest
	no ret
	sender in User
	receiver in Client
}

-- operation Client__HttpResp
sig Client__HttpResp extends Op {
	Client__HttpResp__redirectTo : one URI,
}{
	args in Client__HttpResp__redirectTo
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

run SanityCheck {
  some TrustedServer__HttpReq & SuccessOp
  some MaliciousServer__HttpReq & SuccessOp
  some Client__Visit & SuccessOp
  some Client__HttpResp & SuccessOp
} for 2 but 1 Data, 4 Op, 4 Module


check Confidentiality {
  Confidentiality
} for 2 but 1 Data, 4 Op, 4 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 1 Data, 4 Op, 4 Module
