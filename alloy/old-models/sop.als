open models/basic

-- module Script
sig Script extends Module {
	Script__origin : one Origin,
}{
	all o : this.receives[Script__AccessDOM] | Script__origin = o.(Script__AccessDOM <: Script__AccessDOM__reqOrigin)
	all o : this.sends[HTTPServer__GET] | Script__origin.Origin__domain = o.(HTTPServer__GET <: HTTPServer__GET__url).URL__domain
	all o : this.sends[HTTPServer__POST] | Script__origin.Origin__domain = o.(HTTPServer__POST <: HTTPServer__POST__url).URL__domain
	this.initAccess in NonCriticalData + Script__origin
}

-- module BrowserStore
one sig BrowserStore extends Module {
	BrowserStore__cookies : CookieScope set -> lone Cookie,
}{
	all o : this.receives[BrowserStore__GetCookie] | o.(BrowserStore__GetCookie <: BrowserStore__GetCookie__ret) = BrowserStore__cookies[o.(BrowserStore__GetCookie <: BrowserStore__GetCookie__cs)]
	this.initAccess in NonCriticalData + CookieScope.BrowserStore__cookies + BrowserStore__cookies.Cookie
}

-- module HTTPServer
sig HTTPServer extends Module {
}{
	this.initAccess in NonCriticalData
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = BrowserStore
}

-- operation Script__AccessDOM
sig Script__AccessDOM extends Op {
	Script__AccessDOM__reqOrigin : one Origin,
	Script__AccessDOM__ret : one DOM,
}{
	args in Script__AccessDOM__reqOrigin
	ret in Script__AccessDOM__ret
	sender in Script
	receiver in Script
}

-- operation BrowserStore__GetCookie
sig BrowserStore__GetCookie extends Op {
	BrowserStore__GetCookie__cs : one CookieScope,
	BrowserStore__GetCookie__ret : one Cookie,
}{
	args in BrowserStore__GetCookie__cs
	ret in BrowserStore__GetCookie__ret
	sender in Script
	receiver in BrowserStore
}

-- operation HTTPServer__GET
sig HTTPServer__GET extends Op {
	HTTPServer__GET__url : one URL,
	HTTPServer__GET__req : one HTTPReq,
	HTTPServer__GET__ret : one HTTPResp,
}{
	args in HTTPServer__GET__url + HTTPServer__GET__req
	ret in HTTPServer__GET__ret
	sender in Script
	receiver in HTTPServer
}

-- operation HTTPServer__POST
sig HTTPServer__POST extends Op {
	HTTPServer__POST__url : one URL,
	HTTPServer__POST__req : one HTTPReq,
	HTTPServer__POST__ret : one HTTPResp,
}{
	args in HTTPServer__POST__url + HTTPServer__POST__req
	ret in HTTPServer__POST__ret
	sender in Script
	receiver in HTTPServer
}

-- datatype declarations
abstract sig Str extends Data {
}{
}
sig DOM extends Str {
}{
	no fields
}
sig HTML extends Str {
	HTML__dom : one DOM,
}{
	fields in HTML__dom
}
sig HTTPReq extends Data {
	HTTPReq__headers : set Str,
}{
	fields in HTTPReq__headers
}
sig HTTPResp extends Data {
	HTTPResp__html : one HTML,
	HTTPResp__headers : set Str,
}{
	fields in HTTPResp__html + HTTPResp__headers
}
sig Origin {
	Origin__domain : one Domain,
}
sig Domain {
}
sig Path {
}
sig URL {
	URL__domain : one Domain,
	URL__path : one Path,
}
sig CookieScope {
	CookieScope__domain : one Domain,
	CookieScope__path : one Path,
}
sig Cookie extends Str {
}{
	no fields
}
sig OtherData extends Data {}{ no fields }

run SanityCheck {
  some Script__AccessDOM & SuccessOp
  some BrowserStore__GetCookie & SuccessOp
  some HTTPServer__GET & SuccessOp
  some HTTPServer__POST & SuccessOp
} for 2 but 6 Data, 5 Step,4 Op, 3 Module


check Confidentiality {
  Confidentiality
} for 2 but 6 Data, 5 Step,4 Op, 3 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 6 Data, 5 Step,4 Op, 3 Module

fun RelevantOp : Op -> Step {
  {o : Op, t : Step | o.pre = t and o in SuccessOp}
}
