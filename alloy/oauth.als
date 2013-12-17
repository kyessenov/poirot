open models/basic
open models/crypto[Data]

-- module EndUser
one sig EndUser extends Module {
	EndUser__cred : one Credential,
}{
	all o : this.sends[UserAgent__EnterCred] | triggeredBy[o,EndUser__PromptForCred]
	all o : this.sends[UserAgent__EnterCred] | o.(UserAgent__EnterCred <: UserAgent__EnterCred__cred) = EndUser__cred
	all o : this.sends[UserAgent__EnterCred] | o.(UserAgent__EnterCred <: UserAgent__EnterCred__uri) = o.trigger.((EndUser__PromptForCred <: EndUser__PromptForCred__uri))
	accesses.first in NonCriticalData + EndUser__cred + Credential
}

-- module UserAgent
one sig UserAgent extends Module {
	UserAgent__knownClients : set ClientID,
}{
	all o : this.receives[UserAgent__InitFlow] | (some (UserAgent__knownClients & o.(UserAgent__InitFlow <: UserAgent__InitFlow__id)))
	all o : this.sends[EndUser__PromptForCred] | triggeredBy[o,UserAgent__InitFlow]
	all o : this.sends[EndUser__PromptForCred] | o.(EndUser__PromptForCred <: EndUser__PromptForCred__uri) = o.trigger.((UserAgent__InitFlow <: UserAgent__InitFlow__redirect))
	all o : this.sends[AuthServer__ReqAuth] | triggeredBy[o,UserAgent__EnterCred]
	all o : this.sends[AuthServer__ReqAuth] | o.(AuthServer__ReqAuth <: AuthServer__ReqAuth__cred) = o.trigger.((UserAgent__EnterCred <: UserAgent__EnterCred__cred))
	all o : this.sends[AuthServer__ReqAuth] | o.(AuthServer__ReqAuth <: AuthServer__ReqAuth__uri) = o.trigger.((UserAgent__EnterCred <: UserAgent__EnterCred__uri))
	all o : this.sends[ClientServer__SendAuthResp] | triggeredBy[o,UserAgent__Redirect]
	all o : this.sends[ClientServer__SendAuthResp] | o.(ClientServer__SendAuthResp <: ClientServer__SendAuthResp__uri) = o.trigger.((UserAgent__Redirect <: UserAgent__Redirect__uri))
	(some (ClientServer.ClientServer__id & UserAgent__knownClients))
	accesses.first in NonCriticalData + UserAgent__knownClients
}

-- module ClientServer
one sig ClientServer extends Module {
	ClientServer__addr : one URI,
	ClientServer__id : one ClientID,
	ClientServer__scope : one Scope,
}{
	all o : this.sends[UserAgent__InitFlow] | o.(UserAgent__InitFlow <: UserAgent__InitFlow__redirect) = ClientServer__addr
	accesses.first in NonCriticalData + ClientServer__addr + ClientServer__id + ClientServer__scope
}

-- module AuthServer
one sig AuthServer extends Module {
	AuthServer__authGrants : Credential set -> lone AuthGrant,
	AuthServer__accessTokens : AuthGrant set -> lone AccessToken,
}{
	all o : this.receives[AuthServer__ReqAuth] | (some AuthServer__authGrants[o.(AuthServer__ReqAuth <: AuthServer__ReqAuth__cred)])
	all o : this.receives[AuthServer__ReqAccessToken] | (some AuthServer__accessTokens[o.(AuthServer__ReqAccessToken <: AuthServer__ReqAccessToken__authGrant)])
	all o : this.sends[UserAgent__Redirect] | triggeredBy[o,AuthServer__ReqAuth]
	all o : this.sends[UserAgent__Redirect] | (o.(UserAgent__Redirect <: UserAgent__Redirect__uri).URI__addr = o.trigger.((AuthServer__ReqAuth <: AuthServer__ReqAuth__uri)).URI__addr and (some (o.(UserAgent__Redirect <: UserAgent__Redirect__uri).URI__params & AuthServer__authGrants[o.trigger.((AuthServer__ReqAuth <: AuthServer__ReqAuth__cred))])))
	all o : this.sends[ClientServer__SendAccessToken] | triggeredBy[o,AuthServer__ReqAccessToken]
	all o : this.sends[ClientServer__SendAccessToken] | o.(ClientServer__SendAccessToken <: ClientServer__SendAccessToken__token) = AuthServer__accessTokens[o.trigger.((AuthServer__ReqAccessToken <: AuthServer__ReqAccessToken__authGrant))]
	accesses.first in NonCriticalData + Credential.AuthServer__authGrants + AuthServer__authGrants.AuthGrant + AuthGrant.AuthServer__accessTokens + AuthServer__accessTokens.AccessToken + AuthGrant + AccessToken
}

-- module ResourceServer
one sig ResourceServer extends Module {
	ResourceServer__resources : AccessToken set -> lone Resource,
}{
	all o : this.receives[ResourceServer__ReqResource] | (some ResourceServer__resources[o.(ResourceServer__ReqResource <: ResourceServer__ReqResource__accessToken)])
	all o : this.sends[ClientServer__SendResource] | triggeredBy[o,ResourceServer__ReqResource]
	all o : this.sends[ClientServer__SendResource] | o.(ClientServer__SendResource <: ClientServer__SendResource__res) = ResourceServer__resources[o.trigger.((ResourceServer__ReqResource <: ResourceServer__ReqResource__accessToken))]
	accesses.first in NonCriticalData + AccessToken.ResourceServer__resources + ResourceServer__resources.Resource + Resource
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = EndUser + UserAgent + ClientServer + AuthServer + ResourceServer
}

-- operation EndUser__PromptForCred
sig EndUser__PromptForCred extends Op {
	EndUser__PromptForCred__uri : one URI,
}{
	args in EndUser__PromptForCred__uri
	no ret
	sender in UserAgent
	receiver in EndUser
}

-- operation UserAgent__InitFlow
sig UserAgent__InitFlow extends Op {
	UserAgent__InitFlow__redirect : one URI,
	UserAgent__InitFlow__id : one ClientID,
	UserAgent__InitFlow__scope : one Scope,
}{
	args in UserAgent__InitFlow__redirect + UserAgent__InitFlow__id + UserAgent__InitFlow__scope
	no ret
	sender in ClientServer
	receiver in UserAgent
}

-- operation UserAgent__EnterCred
sig UserAgent__EnterCred extends Op {
	UserAgent__EnterCred__cred : one Credential,
	UserAgent__EnterCred__uri : one URI,
}{
	args in UserAgent__EnterCred__cred + UserAgent__EnterCred__uri
	no ret
	sender in EndUser
	receiver in UserAgent
}

-- operation UserAgent__Redirect
sig UserAgent__Redirect extends Op {
	UserAgent__Redirect__uri : one URI,
}{
	args in UserAgent__Redirect__uri
	no ret
	sender in AuthServer
	receiver in UserAgent
}

-- operation ClientServer__SendAuthResp
sig ClientServer__SendAuthResp extends Op {
	ClientServer__SendAuthResp__uri : one URI,
}{
	args in ClientServer__SendAuthResp__uri
	no ret
	sender in UserAgent
	receiver in ClientServer
}

-- operation ClientServer__SendAccessToken
sig ClientServer__SendAccessToken extends Op {
	ClientServer__SendAccessToken__token : one AccessToken,
}{
	args in ClientServer__SendAccessToken__token
	no ret
	sender in AuthServer
	receiver in ClientServer
}

-- operation ClientServer__SendResource
sig ClientServer__SendResource extends Op {
	ClientServer__SendResource__res : one Resource,
}{
	args in ClientServer__SendResource__res
	no ret
	sender in ResourceServer
	receiver in ClientServer
}

-- operation AuthServer__ReqAuth
sig AuthServer__ReqAuth extends Op {
	AuthServer__ReqAuth__cred : one Credential,
	AuthServer__ReqAuth__uri : one URI,
}{
	args in AuthServer__ReqAuth__cred + AuthServer__ReqAuth__uri
	no ret
	sender in UserAgent
	receiver in AuthServer
}

-- operation AuthServer__ReqAccessToken
sig AuthServer__ReqAccessToken extends Op {
	AuthServer__ReqAccessToken__authGrant : one AuthGrant,
}{
	args in AuthServer__ReqAccessToken__authGrant
	no ret
	sender in ClientServer
	receiver in AuthServer
}

-- operation ResourceServer__ReqResource
sig ResourceServer__ReqResource extends Op {
	ResourceServer__ReqResource__accessToken : one AccessToken,
}{
	args in ResourceServer__ReqResource__accessToken
	no ret
	sender in ClientServer
	receiver in ResourceServer
}

-- datatype declarations
abstract sig Payload extends Data {
}{
}
sig AuthCode extends Payload {
}{
	no fields
}
sig AuthGrant extends Payload {
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
sig ClientID extends Payload {
}{
	no fields
}
sig Scope extends Payload {
}{
	no fields
}
sig Addr extends Data {
}{
	no fields
}
sig URI extends Data {
	URI__addr : one Addr,
	URI__params : set Payload,
}{
	fields in URI__addr + URI__params
}
sig OtherData extends Data {}{ no fields }

-- fact criticalDataFacts
fact criticalDataFacts {
	CriticalData = Resource
}

run SanityCheck {
  some EndUser__PromptForCred & SuccessOp
  some UserAgent__InitFlow & SuccessOp
  some UserAgent__EnterCred & SuccessOp
  some UserAgent__Redirect & SuccessOp
  some ClientServer__SendAuthResp & SuccessOp
  some ClientServer__SendAccessToken & SuccessOp
  some ClientServer__SendResource & SuccessOp
  some AuthServer__ReqAuth & SuccessOp
  some AuthServer__ReqAccessToken & SuccessOp
  some ResourceServer__ReqResource & SuccessOp
} for 1 but 9 Data, 11 Step,10 Op, 5 Module


fun RelevantOp : Op -> Step {
  {o : Op, t : Step | o.post = t and o in SuccessOp}
}
check Confidentiality {
  Confidentiality
} for 1 but 9 Data, 11 Step,10 Op, 5 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 1 but 9 Data, 11 Step,10 Op, 5 Module

