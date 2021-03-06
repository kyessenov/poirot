open models/basicNoStep

-- module Server
one sig Server extends Module {
	Server__responses : URL set -> lone HTML,
}{
	all o : this.sends[Browser__SendResp] | triggeredBy[o,Server__SendReq]
	all o : this.sends[Browser__SendResp] | o.(Browser__SendResp <: Browser__SendResp__resp) = Server__responses[o.trigger.((Server__SendReq <: Server__SendReq__url))]
	this.initAccess in NonCriticalData + URL.Server__responses + Server__responses.HTML
}

-- module Browser
one sig Browser extends Module {
}{
	all o : this.sends[User__DisplayHTML] | triggeredBy[o,Browser__SendResp]
	all o : this.sends[User__DisplayHTML] | o.(User__DisplayHTML <: User__DisplayHTML__html) = o.trigger.((Browser__SendResp <: Browser__SendResp__resp))
	all o : this.sends[Server__SendReq] | triggeredBy[o,Browser__Visit]
	all o : this.sends[Server__SendReq] | o.(Server__SendReq <: Server__SendReq__url) = o.trigger.((Browser__Visit <: Browser__Visit__url))
	this.initAccess in NonCriticalData
}

-- module User
one sig User extends Module {
}{
	this.initAccess in NonCriticalData
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
	User__DisplayHTML__html : one HTML,
}{
	args in User__DisplayHTML__html
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
sig HTML extends Data {
}{
	no fields
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
  some Browser__SendResp & SuccessOp
  some Browser__Visit & SuccessOp
  some User__DisplayHTML & SuccessOp
} for 2 but 6 Data, 4 Op, 3 Module


check Confidentiality {
  Confidentiality
} for 2 but 6 Data, 4 Op, 3 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 6 Data, 4 Op, 3 Module
