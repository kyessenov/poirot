open models/basic
open models/crypto[Data]

-- module Server
one sig Server extends Module {
	Server__sessions : URL set -> lone Cookie,
}{
	all o : this.receives[Server__SendReq] | (some (o.(Server__SendReq <: Server__SendReq__cookies) & Server__sessions[o.(Server__SendReq <: Server__SendReq__url)]))
	all o : this.sends[Browser__SendResp] | triggeredBy[o,Server__SendReq]
	accesses.first in NonCriticalData + URL.Server__sessions + Server__sessions.Cookie
}

-- module Browser
one sig Browser extends Module {
	Browser__cookies : (Addr set -> lone Cookie) -> set Step,
}{
	all o : this.receives[Browser__ExtractCookie] | (some (Browser__cookies.(o.pre)[o.(Browser__ExtractCookie <: Browser__ExtractCookie__addr)] & o.(Browser__ExtractCookie <: Browser__ExtractCookie__ret)))
	all o : this.receives[Browser__OverwriteCookie] | Browser__cookies.(o.post) = (Browser__cookies.(o.pre) + o.(Browser__OverwriteCookie <: Browser__OverwriteCookie__addr) -> o.(Browser__OverwriteCookie <: Browser__OverwriteCookie__cookie))
	all o : this.sends[Server__SendReq] | triggeredBy[o,Browser__Visit]
	all o : this.sends[Server__SendReq] | o.(Server__SendReq <: Server__SendReq__cookies) = Browser__cookies.(o.pre)[o.trigger.((Browser__Visit <: Browser__Visit__url)).URL__addr]
	accesses.first in NonCriticalData + Addr.(Browser__cookies.first) + (Browser__cookies.first).Cookie
}

-- module User
one sig User extends Module {
}{
	accesses.first in NonCriticalData
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = Server + Browser
}

-- operation Server__SendReq
sig Server__SendReq extends Op {
	Server__SendReq__url : one URL,
	Server__SendReq__cookies : set Cookie,
}{
	args = Server__SendReq__url + Server__SendReq__cookies
	no ret
	sender in Browser
	receiver in Server
}

-- operation Browser__Visit
sig Browser__Visit extends Op {
	Browser__Visit__url : one URL,
}{
	args = Browser__Visit__url
	no ret
	sender in User
	receiver in Browser
}

-- operation Browser__SendResp
sig Browser__SendResp extends Op {
	Browser__SendResp__headers : set Pair,
}{
	args = Browser__SendResp__headers
	no ret
	sender in Server
	receiver in Browser
}

-- operation Browser__ExtractCookie
sig Browser__ExtractCookie extends Op {
	Browser__ExtractCookie__addr : one Addr,
	Browser__ExtractCookie__ret : one Cookie,
}{
	args = Browser__ExtractCookie__addr
	ret = Browser__ExtractCookie__ret
	sender in User
	receiver in Browser
}

-- operation Browser__OverwriteCookie
sig Browser__OverwriteCookie extends Op {
	Browser__OverwriteCookie__addr : one Addr,
	Browser__OverwriteCookie__cookie : one Cookie,
}{
	args = Browser__OverwriteCookie__addr + Browser__OverwriteCookie__cookie
	no ret
	sender in User
	receiver in Browser
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
	Pair__n : one Name,
	Pair__v : one Value,
}{
}
sig Cookie extends Pair {
}{
	fields = Pair__n + Pair__v
}
sig URL extends Data {
	URL__addr : one Addr,
	URL__queries : set Pair,
}{
	fields = URL__addr + URL__queries
}
sig OtherData extends Data {}{ no fields }

run SanityCheck {
  some Server__SendReq & SuccessOp
  some Browser__Visit & SuccessOp
  some Browser__SendResp & SuccessOp
  some Browser__ExtractCookie & SuccessOp
  some Browser__OverwriteCookie & SuccessOp
} for 1 but 7 Data, 7 Step, 6 Op

fun RelevantOp : Op -> Step {
  {o : Op, t : Step | o.post = t and o in SuccessOp}
}
check Confidentiality {
  Confidentiality
} for 1 but 7 Data, 7 Step, 6 Op

-- check who can create CriticalData
check Integrity {
  Integrity
} for 1 but 7 Data, 7 Step, 6 Op
