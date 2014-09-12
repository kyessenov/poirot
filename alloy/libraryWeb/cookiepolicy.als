module CookiePolicy

open WebBasic

sig Cookie in Token {
	host : HHost,
	path : lone Path
}

/**
	* Host names are now hierarchical
	*/
sig HHost in Host {
	subsumes : set Host
}

pred unrelated[h1, h2 : Host] {
	some h1 
	some h2
	h1 -> h2 not in subsumes
	h2 -> h1 not in subsumes
	h1 != h2
	no subsumes.h1 & subsumes.h2
}

/**
	* Paths names are now hierarchical
	*/
sig HPath in Path {
	subsumes : set Path
}

/**
	* Browser behavior
	*/
-- true iff the cookie scope matches the url
pred matches[c : Cookie, url : URL] {
	c.host -> url.host in subsumes
	c.path -> url.path in subsumes	
}

pred matches[c : Cookie, h : Host, p : Path] {
	c.host -> h in subsumes
	c.path -> p in subsumes
}

sig CookieReq in HTTPReq {}{
	all c : ret & Cookie | matches[c, url]
}

sig CookieBrowser in Browser {
}{
	all o : this.sends[CookieReq], c : o.args & Cookie | matches[c, o.url]

	-- only release cookies that fall under the same scope
	all o : this.receives[GetCookie] | 
		let c = o.ret |
			c.host -> o.frame.host in subsumes and 
			c.path -> o.frame.path in subsumes
}

-- op for a script to read a cookie
sig GetCookie in DOMOp {
	cookie : Cookie
}{
	sender in Script
	receiver in CookieBrowser
	ret = cookie
	no args
}

run {
	CookieBrowser = Browser
	one Browser
//	some h : HTTPReq | some h.args & Cookie
//	some t : Step | some Script.accesses.t & Cookie
	some SuccessOp & GetCookie
	//some f : CookieFrame | some f.initAccess & Cookie
} for 5 but 2 Op, 8 Module, 8 Data

