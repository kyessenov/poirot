open models/basic
open models/crypto[Data]

-- module User
one sig User extends Module {
	User__intents : set URI,
}{
	all o : this.sends[Client__Visit] | (some (User__intents & o.(Client__Visit <: Client__Visit__dest)))
}

-- module TrustedServer
one sig TrustedServer extends Module {
	TrustedServer__cookies : Op some -> lone Cookie,
	TrustedServer__addr : lone Hostname,
	TrustedServer__protectedOps : set Op,
}{
	all o : this.receives[TrustedServer__HttpReq] | ((some (TrustedServer__protectedOps & o)) implies arg[o.(TrustedServer__HttpReq <: TrustedServer__HttpReq__cookie)] = TrustedServer__cookies[o])
	all o : this.sends[Client__HttpResp] | triggeredBy[o,TrustedServer__HttpReq]
}

-- module MaliciousServer
one sig MaliciousServer extends Module {
	MaliciousServer__addr : lone Hostname,
}{
	all o : this.sends[Client__HttpResp] | triggeredBy[o,MaliciousServer__HttpReq]
}

-- module Client
one sig Client extends Module {
	Client__cookies : URI some -> lone Cookie,
}{
	all o : this.sends[TrustedServer__HttpReq] | 
		(((triggeredBy[o,Client__Visit] and o.(TrustedServer__HttpReq <: TrustedServer__HttpReq__cookie) = Client__cookies[o.trigger.((Client__Visit <: Client__Visit__dest))]) and o.(TrustedServer__HttpReq <: TrustedServer__HttpReq__addr) = o.trigger.((Client__Visit <: Client__Visit__dest)))
		or
		((triggeredBy[o,Client__HttpResp] and o.(TrustedServer__HttpReq <: TrustedServer__HttpReq__cookie) = Client__cookies[o.trigger.((Client__HttpResp <: Client__HttpResp__addr))]) and (some (o.trigger.((Client__HttpResp <: Client__HttpResp__dom)).DOM__tags.ImgTag__src & o.(TrustedServer__HttpReq <: TrustedServer__HttpReq__addr))))
		)
	all o : this.sends[MaliciousServer__HttpReq] | 
		(((triggeredBy[o,Client__Visit] and o.(MaliciousServer__HttpReq <: MaliciousServer__HttpReq__cookie) = Client__cookies[o.trigger.((Client__Visit <: Client__Visit__dest))]) and o.(MaliciousServer__HttpReq <: MaliciousServer__HttpReq__addr) = o.trigger.((Client__Visit <: Client__Visit__dest)))
		or
		((triggeredBy[o,Client__HttpResp] and o.(MaliciousServer__HttpReq <: MaliciousServer__HttpReq__cookie) = Client__cookies[o.trigger.((Client__HttpResp <: Client__HttpResp__addr))]) and (some (o.trigger.((Client__HttpResp <: Client__HttpResp__dom)).DOM__tags.ImgTag__src & o.(MaliciousServer__HttpReq <: MaliciousServer__HttpReq__addr))))
		)
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = User + TrustedServer + Client
}

-- operation TrustedServer__HttpReq
sig TrustedServer__HttpReq extends Op {
	TrustedServer__HttpReq__cookie : lone Cookie,
	TrustedServer__HttpReq__addr : lone URI,
}{
	args = TrustedServer__HttpReq__cookie + TrustedServer__HttpReq__addr
	sender in Client
	receiver in TrustedServer
}

-- operation MaliciousServer__HttpReq
sig MaliciousServer__HttpReq extends Op {
	MaliciousServer__HttpReq__cookie : lone Cookie,
	MaliciousServer__HttpReq__addr : lone URI,
}{
	args = MaliciousServer__HttpReq__cookie + MaliciousServer__HttpReq__addr
	sender in Client
	receiver in MaliciousServer
}

-- operation Client__Visit
sig Client__Visit extends Op {
	Client__Visit__dest : lone URI,
}{
	args = Client__Visit__dest
	sender in User
	receiver in Client
}

-- operation Client__HttpResp
sig Client__HttpResp extends Op {
	Client__HttpResp__dom : lone DOM,
	Client__HttpResp__addr : lone URI,
}{
	args = Client__HttpResp__dom + Client__HttpResp__addr
	sender in TrustedServer + MaliciousServer
	receiver in Client
}

-- fact dataFacts
fact dataFacts {
	creates.Cookie in TrustedServer
	creates.DOM in TrustedServer + MaliciousServer
}

-- datatype declarations
abstract sig Payload extends Data {
}{
}
sig Cookie extends Payload {
}{
	no fields
}
sig OtherPayload extends Payload {
}{
	no fields
}
sig Hostname extends Data {
}{
	no fields
}
sig Addr extends Data {
}{
	no fields
}
sig URI extends Data {
	URI__addr : lone Addr,
	URI__params : set Payload,
}{
	fields = URI__addr + URI__params
}
abstract sig HtmlTag extends Data {
}{
}
sig ImgTag extends HtmlTag {
	ImgTag__src : lone URI,
}{
	fields = ImgTag__src
}
sig DOM extends Payload {
	DOM__tags : set HtmlTag,
}{
	fields = DOM__tags
}
sig OtherData extends Data {}{ no fields }


fun RelevantOp : Op -> Step {
	{o : Op, t : Step | o.post = t and o in SuccessOp}
}

run SanityCheck {
	all m : Module |
		some sender.m & SuccessOp
} for 1 but 9 Data, 10 Step, 9 Op

check LimitedAccess {
no t : Step | some UntrustedModule.accesses.t & Article and Browser.Browser__numAccessed in AboveLimit
} for 1 but 9 Data, 10 Step, 9 Op, 1 Article

check Confidentiality {
   Confidentiality
} for 1 but 9 Data, 10 Step, 9 Op

-- check who can create CriticalData
check Integrity {
   Integrity
} for 1 but 9 Data, 10 Step, 9 Op
