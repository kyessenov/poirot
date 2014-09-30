/**
	*	CRSF using a form POST 
	*/
module CSRF

open SOP

sig TargetServer in HttpServer {}
sig CSRFScript in Script {}{
	this in SOPScript
}

sig FormSubmit in POST {
}{
	receiver in TargetServer
	sender in CSRFScript
	this not in SOPReq	-- does not follow the rules of SOP
	no ret						-- but you don't get any response
}

run {
	some FormSubmit & SuccessOp
} for 3
