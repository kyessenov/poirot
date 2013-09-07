open models/basic
open models/crypto[Data]

-- module EndUser
one sig EndUser extends Module {
	cred : lone Credential,
}{
	all o : this.sends[EnterCred] | triggeredBy[o,PromptForCred]
	all o : this.sends[EnterCred] | o.(EnterCred <: cred) = cred
	all o : this.sends[EnterCred] | o.(EnterCred <: uri) = o.trigger.((PromptForCred <: uri))
}

-- module UserAgent
one sig UserAgent extends Module {
}{
	all o : this.sends[PromptForCred] | triggeredBy[o,InitFlow]
	all o : this.sends[PromptForCred] | o.(PromptForCred <: uri) = o.trigger.((InitFlow <: redirectURI))
	all o : this.sends[ReqAuth] | triggeredBy[o,EnterCred]
	all o : this.sends[ReqAuth] | o.(ReqAuth <: cred) = o.trigger.((EnterCred <: cred))
	all o : this.sends[ReqAuth] | o.(ReqAuth <: uri) = o.trigger.((EnterCred <: uri))
	all o : this.sends[SendAuthResp] | triggeredBy[o,Redirect]
	all o : this.sends[SendAuthResp] | o.(SendAuthResp <: uri) = o.trigger.((Redirect <: uri))
}

-- module ClientServer
one sig ClientServer extends Module {
	addr : lone Addr,
}{
	all o : this.sends[InitFlow] | o.(InitFlow <: redirectURI) = addr
}

-- module AuthServer
one sig AuthServer extends Module {
	authGrants : Credential -> AuthGrant,
	accessTokens : AuthGrant -> AccessToken,
}{
	all o : this.receives[ReqAuth] | (some authGrants[arg[o.(ReqAuth <: cred)]])
	all o : this.receives[ReqAccessToken] | (some accessTokens[arg[o.(ReqAccessToken <: authGrant)]])
	all o : this.sends[Redirect] | triggeredBy[o,ReqAuth]
	all o : this.sends[Redirect] | (o.(Redirect <: uri).addr = o.trigger.((ReqAuth <: uri)).addr and (some (o.(Redirect <: uri).vals & o.trigger.((ReqAuth <: cred)).authGrants)))
	all o : this.sends[SendAccessToken] | triggeredBy[o,ReqAccessToken]
	all o : this.sends[SendAccessToken] | o.(SendAccessToken <: token) = o.trigger.((ReqAccessToken <: authGrant)).accessTokens
}

-- module ResourceServer
one sig ResourceServer extends Module {
	resources : AccessToken -> Resource,
}{
	all o : this.receives[ReqResource] | (some resources[arg[o.(ReqResource <: accessToken)]])
	all o : this.sends[SendResource] | triggeredBy[o,ReqResource]
	all o : this.sends[SendResource] | o.(SendResource <: data) = o.trigger.((ReqResource <: accessToken)).resources
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = EndUser + UserAgent + ClientServer + AuthServer + ResourceServer
}

-- operation PromptForCred
sig PromptForCred extends Op {
	uri : lone URI,
}{
	args = uri
	sender in UserAgent
	receiver in EndUser
}

-- operation InitFlow
sig InitFlow extends Op {
	redirectURI : lone URI,
}{
	args = redirectURI
	sender in ClientServer
	receiver in UserAgent
}

-- operation EnterCred
sig EnterCred extends Op {
	cred : lone Credential,
	uri : lone URI,
}{
	args = cred + uri
	sender in EndUser
	receiver in UserAgent
}

-- operation Redirect
sig Redirect extends Op {
	uri : lone URI,
}{
	args = uri
	sender in AuthServer
	receiver in UserAgent
}

-- operation SendAuthResp
sig SendAuthResp extends Op {
	uri : lone URI,
}{
	args = uri
	sender in UserAgent
	receiver in ClientServer
}

-- operation SendAccessToken
sig SendAccessToken extends Op {
	token : lone AccessToken,
}{
	args = token
	sender in AuthServer
	receiver in ClientServer
}

-- operation SendResource
sig SendResource extends Op {
	data : lone Payload,
}{
	args = data
	sender in ResourceServer
	receiver in ClientServer
}

-- operation ReqAuth
sig ReqAuth extends Op {
	cred : lone Credential,
	uri : lone URI,
}{
	args = cred + uri
	sender in UserAgent
	receiver in AuthServer
}

-- operation ReqAccessToken
sig ReqAccessToken extends Op {
	authGrant : lone AuthGrant,
}{
	args = authGrant
	sender in ClientServer
	receiver in AuthServer
}

-- operation ReqResource
sig ReqResource extends Op {
	accessToken : lone AccessToken,
}{
	args = accessToken
	sender in ClientServer
	receiver in ResourceServer
}

-- fact dataFacts
fact dataFacts {
	creates.Payload in EndUser + AuthServer + AuthServer + ResourceServer
	creates.AuthGrant in AuthServer
	creates.Credential in EndUser
	creates.AccessToken in AuthServer
	creates.Resource in ResourceServer
}

-- datatype declarations
abstract sig Payload extends Data {
}{
}
abstract sig AuthGrant extends Payload {
}{
}
sig AuthCode extends AuthGrant {
}{
	no fields
}
sig Credential extends Payload {
}{
	no fields
}
sig AccessToken extends Payload {
}{
	no fields
}
sig Resource extends Payload {
}{
	no fields
}
sig OtherPayload extends Payload {
}{
	no fields
}
sig Addr extends Data {
}{
	no fields
}
sig URI extends Data {
	addr : lone Addr,
	vals : set Payload,
}{
	fields = addr + vals
}
sig OtherData extends Data {}{ no fields }

-- fact criticalDataFacts
fact criticalDataFacts {
	CriticalData = Resource
}


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
