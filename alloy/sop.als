open models/basicNoStep

-- module Script
sig Script extends Module {
	Script__origin : one Origin,
	Script__doms : set DOM,
}{
	all o : this.receives[Script__Resp] | (some (Script__doms & o.(Script__Resp <: Script__Resp__html).HTML__dom))
	all o : this.receives[Script__AccessDOM] | (some (Script__doms & o.(Script__AccessDOM <: Script__AccessDOM__ret)))
	this.initAccess in NonCriticalData + Script__origin + Script__doms
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
	all o : this.sends[Script__Resp] | 
		(triggeredBy[o,HTTPServer__GET]
		or
		triggeredBy[o,HTTPServer__POST]
		)
	this.initAccess in NonCriticalData
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = BrowserStore
}

-- operation Script__Resp
sig Script__Resp extends Op {
	Script__Resp__html : one HTML,
	Script__Resp__headers : set RespHeader,
}{
	args in Script__Resp__html + Script__Resp__headers
	no ret
	sender in HTTPServer
	receiver in Script
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
	HTTPServer__GET__headers : set ReqHeader,
}{
	args in HTTPServer__GET__url + HTTPServer__GET__headers
	no ret
	sender in Script
	receiver in HTTPServer
}

-- operation HTTPServer__POST
sig HTTPServer__POST extends Op {
	HTTPServer__POST__url : one URL,
	HTTPServer__POST__headers : set ReqHeader,
	HTTPServer__POST__params : set Param,
}{
	args in HTTPServer__POST__url + HTTPServer__POST__headers + HTTPServer__POST__params
	no ret
	sender in Script
	receiver in HTTPServer
}

-- datatype declarations
sig DOM extends Data {
}{
	no fields
}
sig HTML extends Data {
	HTML__dom : one DOM,
}{
	fields in HTML__dom
}
sig Origin extends Data {
}{
	no fields
}
sig Domain extends Data {
}{
	no fields
}
sig Path extends Data {
}{
	no fields
}
sig URL extends Data {
}{
	no fields
}
sig ReqHeader extends Data {
}{
	no fields
}
sig RespHeader extends Data {
}{
	no fields
}
sig Param extends Data {
}{
	no fields
}
sig CookieScope extends Data {
	CookieScope__domain : one Domain,
	CookieScope__path : one Path,
}{
	fields in CookieScope__domain + CookieScope__path
}
sig Cookie extends Data {
}{
	no fields
}
sig OtherData extends Data {}{ no fields }

run SanityCheck {
  some Script__Resp & SuccessOp
  some Script__AccessDOM & SuccessOp
  some BrowserStore__GetCookie & SuccessOp
  some HTTPServer__GET & SuccessOp
  some HTTPServer__POST & SuccessOp
} for 1 but 11 Data, 5 Op, 3 Module


check Confidentiality {
  Confidentiality
} for 1 but 11 Data, 5 Op, 3 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 1 but 11 Data, 5 Op, 3 Module
