open models/basic
open models/crypto[Data]

-- module Server
one sig Server extends Module {
	Server__responses : URL set -> lone HTML,
}{
	all o : this.sends[Browser__SendResp] | triggeredBy[o,Server__SendReq]
	all o : this.sends[Browser__SendResp] | o.(Browser__SendResp <: Browser__SendResp__resp) = Server__responses[o.trigger.((Server__SendReq <: Server__SendReq__url))]
	accesses.first in NonCriticalData + URL.Server__responses + Server__responses.HTML
}

-- module ScriptProc
sig ScriptProc extends Module {
	ScriptProc__original : one HTML,
	ScriptProc__transformed : one HTML,
}{
	all o : this.receives[ScriptProc__Exec] | o.(ScriptProc__Exec <: ScriptProc__Exec__ret) = ScriptProc__transformed
	accesses.first in NonCriticalData + ScriptProc__original + ScriptProc__transformed
}

-- module Browser
one sig Browser extends Module {
	Browser__transform : HTML set -> lone HTML,
}{
	all o : this.sends[User__DisplayHTML] | triggeredBy[o,Browser__SendResp]
	all o : this.sends[User__DisplayHTML] | o.(User__DisplayHTML <: User__DisplayHTML__resp) = Browser__transform[o.trigger.((Browser__SendResp <: Browser__SendResp__resp))]
	all o : this.sends[ScriptProc__Exec] | triggeredBy[o,Browser__SendResp]
	all o : this.sends[ScriptProc__Exec] | o.(ScriptProc__Exec <: ScriptProc__Exec__ret) = Browser__transform[o.trigger.((Browser__SendResp <: Browser__SendResp__resp))]
	all o : this.sends[Server__SendReq] | triggeredBy[o,Browser__Visit]
	all o : this.sends[Server__SendReq] | o.(Server__SendReq <: Server__SendReq__url) = o.trigger.((Browser__Visit <: Browser__Visit__url))
	accesses.first in NonCriticalData + HTML.Browser__transform + Browser__transform.HTML
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
	Server__SendReq__headers : set Pair,
}{
	args in Server__SendReq__url + Server__SendReq__headers
	no ret
	sender in Browser
	receiver in Server
}

-- operation ScriptProc__Exec
sig ScriptProc__Exec extends Op {
	ScriptProc__Exec__ret : one HTML,
}{
	no args
	ret in ScriptProc__Exec__ret
	sender in Browser
	receiver in ScriptProc
}

-- operation Browser__SendResp
sig Browser__SendResp extends Op {
	Browser__SendResp__resp : one HTML,
	Browser__SendResp__headers : set Pair,
}{
	args in Browser__SendResp__resp + Browser__SendResp__headers
	no ret
	sender in Server
	receiver in Browser
}

-- operation Browser__Visit
sig Browser__Visit extends Op {
	Browser__Visit__url : one URL,
}{
	args in Browser__Visit__url
	no ret
	sender in User
	receiver in Browser
}

-- operation User__DisplayHTML
sig User__DisplayHTML extends Op {
	User__DisplayHTML__resp : one HTML,
}{
	args in User__DisplayHTML__resp
	no ret
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
sig Script extends Data {
}{
	no fields
}
sig HTML extends Data {
	HTML__script : one Script,
}{
	fields in HTML__script
}
sig Pair extends Data {
	Pair__n : one Name,
	Pair__v : one Value,
}{
	fields in Pair__n + Pair__v
}
sig URL extends Data {
	URL__addr : one Addr,
	URL__queries : set Pair,
}{
	fields in URL__addr + URL__queries
}
sig OtherData extends Data {}{ no fields }

run SanityCheck {
  some Server__SendReq & SuccessOp
  some ScriptProc__Exec & SuccessOp
  some Browser__SendResp & SuccessOp
  some Browser__Visit & SuccessOp
  some User__DisplayHTML & SuccessOp
} for 1 but 7 Data, 6 Step,5 Op, 4 Module


fun RelevantOp : Op -> Step {
  {o : Op, t : Step | o.post = t and o in SuccessOp}
}
check Confidentiality {
  Confidentiality
} for 1 but 7 Data, 6 Step,5 Op, 4 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 1 but 7 Data, 6 Step,5 Op, 4 Module

