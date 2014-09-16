/**
	*	Coss-site scripting
	*/
module XSS

open WebBasic

sig SanitizingServer in HttpServer {
	sanitizes : set HTTPReq
}{
	sanitizes.receiver in this
	all o : sanitizes | 
		no o.resource.encodes & HTML
}

sig InjectedScript in Script {
}{
	some HTML & script.this.encodes
}

-- commands
run {
	some s : HttpServer, o : s.receives[HTTPReq] |
		o not in s.sanitizes
} for 3
