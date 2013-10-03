open models/basic
open models/crypto[Data]

-- module Client
one sig Client extends Module {
	Client__cookies : (Addr some -> lone Cookie) -> some Step,
}{
	all o : this.receives[Client__SetCookie] | Client__cookies.(o.post) = (Client__cookies.(o.pre) + arg[o.(Client__SetCookie <: Client__SetCookie__addr)] -> arg[o.(Client__SetCookie <: Client__SetCookie__cookie)])
	all o : this.sends[User__Display] | 
		((triggeredBy[o,Client__GetCookie] and o.(User__Display <: User__Display__text) = Client__cookies.(o.pre)[o.trigger.((Client__GetCookie <: Client__GetCookie__addr))])
		or
		(triggeredBy[o,Client__SendResp] and o.(User__Display <: User__Display__text) = o.trigger.((Client__SendResp <: Client__SendResp__body)))
		)
	all o : this.sends[Server__SendReq] | triggeredBy[o,Client__Visit]
	all o : this.sends[Server__SendReq] | (o.(Server__SendReq <: Server__SendReq__url) = o.trigger.((Client__Visit <: Client__Visit__url)) and o.(Server__SendReq <: Server__SendReq__headers).AMap___get[NameCookie] = Client__cookies.(o.pre)[o.trigger.((Client__Visit <: Client__Visit__url)).URL__addr])
}

-- module Server
one sig Server extends Module {
	Server__session : URL some -> lone Cookie,
}{
	all o : this.sends[Client__SendResp] | triggeredBy[o,Server__SendReq]
}

-- module User
one sig User extends Module {
}

-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = Client + Server
}

-- operation Client__SetCookie
sig Client__SetCookie extends Op {
	Client__SetCookie__addr : lone Addr,
	Client__SetCookie__cookie : lone Cookie,
}{
	args = Client__SetCookie__addr + Client__SetCookie__cookie
	sender in User
	receiver in Client
}

-- operation Client__GetCookie
sig Client__GetCookie extends Op {
	Client__GetCookie__addr : lone Addr,
}{
	args = Client__GetCookie__addr
	sender in User
	receiver in Client
}

-- operation Client__SendResp
sig Client__SendResp extends Op {
	Client__SendResp__headers : lone AMap,
	Client__SendResp__body : lone Str,
}{
	args = Client__SendResp__headers + Client__SendResp__body
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

-- operation Server__SendReq
sig Server__SendReq extends Op {
	Server__SendReq__url : lone URL,
	Server__SendReq__headers : lone AMap,
}{
	args = Server__SendReq__url + Server__SendReq__headers
	sender in Client
	receiver in Server
}

-- operation User__Display
sig User__Display extends Op {
	User__Display__text : lone Str,
}{
	args = User__Display__text
	sender in Client
	receiver in User
}

-- fact dataFacts
fact dataFacts {
	creates.Cookie in Client
}

-- datatype declarations
abstract sig Str extends Data {
}{
}
sig Addr extends Str {
}{
	no fields
}
sig Name extends Str {
}{
	no fields
}
sig Pair extends Str {
	Pair__n : lone Name,
	Pair__v : lone Str,
}{
	fields = Pair__n + Pair__v
}
sig AMap extends Str {
	AMap__entries : set Pair,
}{
	fields = AMap__entries
}
sig URL extends Str {
	URL__addr : lone Addr,
	URL__queries : lone AMap,
}{
	fields = URL__addr + URL__queries
}
sig Cookie extends Str {
	Cookie__domain : lone Addr,
	Cookie__content : lone Pair,
}{
	fields = Cookie__domain + Cookie__content
}
sig NameCookie extends Name {
}{
	no fields
}
sig OtherData extends Data {}{ no fields }
fun AMap___get[self: AMap, k: Name]: Str {
  ({p: self.AMap__entries | p.Pair__n = k}).Pair__v
}


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
