open models/basic
open models/crypto[Data]

-- module Server
one sig Server extends Module {
	Server__responses : URL some -> lone HTML,
}{
	all o : this.sends[Client__SendResp] | triggeredBy[o,Server__SendReq]
	all o : this.sends[Client__SendResp] | o.(Client__SendResp <: Client__SendResp__resp) = Server__responses[o.trigger.((Server__SendReq <: Server__SendReq__url))]
}

-- module Client
one sig Client extends Module {
}{
	all o : this.sends[User__Display] | triggeredBy[o,Client__SendResp]
	all o : this.sends[User__Display] | o.(User__Display <: User__Display__resp) = o.trigger.((Client__SendResp <: Client__SendResp__resp))
	all o : this.sends[Server__SendReq] | triggeredBy[o,Client__Visit]
	all o : this.sends[Server__SendReq] | o.(Server__SendReq <: Server__SendReq__url) = o.trigger.((Client__Visit <: Client__Visit__url))
}

-- module User
one sig User extends Module {
}

-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = Server + Client
}

-- operation Server__SendReq
sig Server__SendReq extends Op {
	Server__SendReq__url : lone URL,
}{
	args = Server__SendReq__url
	sender in Client
	receiver in Server
}

-- operation Client__SendResp
sig Client__SendResp extends Op {
	Client__SendResp__resp : lone HTML,
}{
	args = Client__SendResp__resp
	sender in Server
	receiver in Client
}

-- operation Client__Visit
sig Client__Visit extends Op {
	Client__Visit__url : lone URL,
}{
	args = Client__Visit__url
	sender in User
	receiver in Client
}

-- operation User__Display
sig User__Display extends Op {
	User__Display__resp : lone HTML,
}{
	args = User__Display__resp
	sender in Client
	receiver in User
}

-- datatype declarations
sig Str extends Data {
}{
	no fields
}
sig URL extends Data {
	URL__addr : lone Str,
	URL__query : lone Str,
}{
	fields = URL__addr + URL__query
}
sig HTML extends Data {
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
