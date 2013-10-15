open models/basic
open models/crypto[Data]

-- module Server
one sig Server extends Module {
	Server__sessions : URL set -> lone Cookie,
}{
	all o : this.receives[Server__SendReq] | (some (arg[o.(Server__SendReq <: Server__SendReq__cookies)] & Server__sessions[arg[o.(Server__SendReq <: Server__SendReq__url)]]))
	all o : this.sends[Browser__SendResp] | triggeredBy[o,Server__SendReq]
}

-- module Browser
one sig Browser extends Module {
	Browser__cookies : (Addr set -> lone Cookie) -> set Step,
}{
	all o : this.receives[Browser__OverwriteCookie] | Browser__cookies.(o.post) = (Browser__cookies.(o.pre) + arg[o.(Browser__OverwriteCookie <: Browser__OverwriteCookie__addr)] -> arg[o.(Browser__OverwriteCookie <: Browser__OverwriteCookie__cookie)])
	all o : this.sends[Server__SendReq] | triggeredBy[o,Browser__Visit]
	all o : this.sends[Server__SendReq] | (o.(Server__SendReq <: Server__SendReq__url) = o.trigger.((Browser__Visit <: Browser__Visit__url)) and o.(Server__SendReq <: Server__SendReq__cookies) = Browser__cookies.(o.pre)[o.trigger.((Browser__Visit <: Browser__Visit__url)).URL__addr])
	all o : this.sends[User__Display] | triggeredBy[o,Browser__ExtractCookie]
	all o : this.sends[User__Display] | o.(User__Display <: User__Display__c) = Browser__cookies.(o.pre)[o.trigger.((Browser__ExtractCookie <: Browser__ExtractCookie__addr))]
}

-- module User
one sig User extends Module {
}

-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = Server + Browser
}

-- operation Server__SendReq
sig Server__SendReq extends Op {
	Server__SendReq__url : lone URL,
	Server__SendReq__cookies : set Cookie,
}{
	args = Server__SendReq__url + Server__SendReq__cookies
	sender in Browser
	receiver in Server
}

-- operation Browser__Visit
sig Browser__Visit extends Op {
	Browser__Visit__url : lone URL,
}{
	args = Browser__Visit__url
	sender in User
	receiver in Browser
}

-- operation Browser__SendResp
sig Browser__SendResp extends Op {
	Browser__SendResp__headers : set Pair,
}{
	args = Browser__SendResp__headers
	sender in Server
	receiver in Browser
}

-- operation Browser__ExtractCookie
sig Browser__ExtractCookie extends Op {
	Browser__ExtractCookie__addr : lone Addr,
}{
	args = Browser__ExtractCookie__addr
	sender in User
	receiver in Browser
}

-- operation Browser__OverwriteCookie
sig Browser__OverwriteCookie extends Op {
	Browser__OverwriteCookie__addr : lone Addr,
	Browser__OverwriteCookie__cookie : lone Cookie,
}{
	args = Browser__OverwriteCookie__addr + Browser__OverwriteCookie__cookie
	sender in User
	receiver in Browser
}

-- operation User__Display
sig User__Display extends Op {
	User__Display__c : lone Cookie,
}{
	args = User__Display__c
	sender in Browser
	receiver in User
}

-- datatype declarations
sig Addr extends Data {
}{
	no fields
}
sig Name extends Data {
}{
	no fields
}
sig Value extends Data {
}{
	no fields
}
sig Pair extends Data {
	Pair__n : lone Name,
	Pair__v : lone Value,
}{
	fields = Pair__n + Pair__v
}
sig Cookie extends Pair {
}{
	no fields
}
sig URL extends Data {
	URL__addr : lone Addr,
	URL__queries : set Pair,
}{
	fields = URL__addr + URL__queries
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
