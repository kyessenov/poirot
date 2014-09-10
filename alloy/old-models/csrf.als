open models/basic

-- module User
one sig User extends Module {
	User__intents : set URI,
}{
	all o : this.sends[Client__Visit] | (some (User__intents & o.(Client__Visit <: Client__Visit__dest)))
	this.initAccess in NonCriticalData + User__intents
}

-- module TrustedServer
one sig TrustedServer extends Module {
	TrustedServer__cookies : Op set -> lone Cookie,
	TrustedServer__addr : one Hostname,
	TrustedServer__protectedOps : set Op,
}{
	all o : this.receives[TrustedServer__HttpReq] | ((some (TrustedServer__protectedOps & o)) implies o.(TrustedServer__HttpReq <: TrustedServer__HttpReq__cookie) = TrustedServer__cookies[o])
	all o : this.sends[Client__HttpResp] | triggeredBy[o,TrustedServer__HttpReq]
	this.initAccess in NonCriticalData + Op.TrustedServer__cookies + TrustedServer__cookies.Cookie + TrustedServer__addr + TrustedServer__protectedOps + DOM + Cookie
}

-- module MaliciousServer
one sig MaliciousServer extends Module {
	MaliciousServer__addr : one Hostname,
}{
	all o : this.sends[Client__HttpResp] | triggeredBy[o,MaliciousServer__HttpReq]
	this.initAccess in NonCriticalData + MaliciousServer__addr + DOM
}

-- module Client
one sig Client extends Module {
	Client__cookies : URI set -> lone Cookie,
}{
	all o : this.sends[TrustedServer__HttpReq] | 
		(((triggeredBy[o,Client__Visit] and o.(TrustedServer__HttpReq <: TrustedServer__HttpReq__cookie) = TrustedServer__cookies[o.trigger.((Client__Visit <: Client__Visit__dest))]) and o.(TrustedServer__HttpReq <: TrustedServer__HttpReq__addr) = o.trigger.((Client__Visit <: Client__Visit__dest)))
		or
		((triggeredBy[o,Client__HttpResp] and o.(TrustedServer__HttpReq <: TrustedServer__HttpReq__cookie) = TrustedServer__cookies[o.trigger.((Client__HttpResp <: Client__HttpResp__addr))]) and (some (o.trigger.((Client__HttpResp <: Client__HttpResp__dom)).DOM__tags.ImgTag__src & o.(TrustedServer__HttpReq <: TrustedServer__HttpReq__addr))))
		)
	all o : this.sends[MaliciousServer__HttpReq] | 
		(((triggeredBy[o,Client__Visit] and o.(MaliciousServer__HttpReq <: MaliciousServer__HttpReq__cookie) = TrustedServer__cookies[o.trigger.((Client__Visit <: Client__Visit__dest))]) and o.(MaliciousServer__HttpReq <: MaliciousServer__HttpReq__addr) = o.trigger.((Client__Visit <: Client__Visit__dest)))
		or
		((triggeredBy[o,Client__HttpResp] and o.(MaliciousServer__HttpReq <: MaliciousServer__HttpReq__cookie) = TrustedServer__cookies[o.trigger.((Client__HttpResp <: Client__HttpResp__addr))]) and (some (o.trigger.((Client__HttpResp <: Client__HttpResp__dom)).DOM__tags.ImgTag__src & o.(MaliciousServer__HttpReq <: MaliciousServer__HttpReq__addr))))
		)
	this.initAccess in NonCriticalData + URI.Client__cookies + Client__cookies.Cookie
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = User + TrustedServer + Client
}

-- operation TrustedServer__HttpReq
sig TrustedServer__HttpReq extends Op {
	TrustedServer__HttpReq__cookie : one Cookie,
	TrustedServer__HttpReq__addr : one URI,
}{
	args in TrustedServer__HttpReq__cookie + TrustedServer__HttpReq__addr
	no ret
	sender in Client
	receiver in TrustedServer
}

-- operation MaliciousServer__HttpReq
sig MaliciousServer__HttpReq extends Op {
	MaliciousServer__HttpReq__cookie : one Cookie,
	MaliciousServer__HttpReq__addr : one URI,
}{
	args in MaliciousServer__HttpReq__cookie + MaliciousServer__HttpReq__addr
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
	Client__HttpResp__dom : one DOM,
	Client__HttpResp__addr : one URI,
}{
	args in Client__HttpResp__dom + Client__HttpResp__addr
	no ret
	sender in TrustedServer + MaliciousServer
	receiver in Client
}

-- datatype declarations
abstract sig Payload extends Data {
}{
}
abstract sig HtmlTag extends Data {
}{
}
sig Hostname extends Data {
}{
	no fields
}
sig Addr extends Data {
}{
	no fields
}
sig Cookie extends Payload {
}{
	no fields
}
sig OtherPayload extends Payload {
}{
	no fields
}
sig URI extends Data {
	URI__addr : one Addr,
	URI__params : set Payload,
}{
	fields in URI__addr + URI__params
}
sig ImgTag extends HtmlTag {
	ImgTag__src : one URI,
}{
	fields in ImgTag__src
}
sig DOM extends Payload {
	DOM__tags : set HtmlTag,
}{
	fields in DOM__tags
}
sig OtherData extends Data {}{ no fields }

run SanityCheck {
  some TrustedServer__HttpReq & SuccessOp
  some MaliciousServer__HttpReq & SuccessOp
  some Client__Visit & SuccessOp
  some Client__HttpResp & SuccessOp
} for 2 but 9 Data, 4 Op, 4 Module


check Confidentiality {
  Confidentiality
} for 2 but 9 Data, 4 Op, 4 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 9 Data, 4 Op, 4 Module
