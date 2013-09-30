open models/basic
open models/crypto[Data]

-- module Server
one sig Server extends Module {
}{
	all o : this.sends[Client__SendResp] | triggeredBy[o,Server__SendReq]
}

-- module Client
one sig Client extends Module {
}

-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = Server + Client
}

-- operation Server__SendReq
sig Server__SendReq extends Op {
	Server__SendReq__req : lone HTTPReq,
}{
	args = Server__SendReq__req
	sender in Client
	receiver in Server
}

-- operation Client__SendResp
sig Client__SendResp extends Op {
	Client__SendResp__resp : lone HTTPResp,
}{
	args = Client__SendResp__resp
	sender in Server
	receiver in Client
}

-- datatype declarations
abstract sig Str extends Data {
}{
}
sig Addr extends Str {
}{
	no fields
}
sig URL extends Data {
	URL__addr : lone Addr,
	URL__queries : set Str,
}{
	fields = URL__addr + URL__queries
}
sig HTTPReq extends Data {
	HTTPReq__url : lone URL,
	HTTPReq__headers : set Str,
}{
	fields = HTTPReq__url + HTTPReq__headers
}
sig HTTPResp extends Data {
	HTTPResp__body : lone Str,
}{
	fields = HTTPResp__body
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
