open models/basic
open models/crypto[Data]

-- module EndUser
one sig EndUser extends Module {
	EndUser__cred : lone Credential,
}{
	all o : this.sends[UserAgent__EnterCred] | triggeredBy[o,EndUser__PromptForCred]
	all o : this.sends[UserAgent__EnterCred] | o.(UserAgent__EnterCred <: UserAgent__EnterCred__cred) = EndUser__cred
	all o : this.sends[UserAgent__EnterCred] | o.(UserAgent__EnterCred <: UserAgent__EnterCred__uri) = o.trigger.((EndUser__PromptForCred <: EndUser__PromptForCred__uri))
}

-- module UserAgent
one sig UserAgent extends Module {
	UserAgent__knownClients : set ClientID,
}{
	all o : this.receives[UserAgent__InitFlow] | (some (UserAgent__knownClients & arg[o.(UserAgent__InitFlow <: UserAgent__InitFlow__id)]))
	all o : this.sends[EndUser__PromptForCred] | triggeredBy[o,UserAgent__InitFlow]
	all o : this.sends[EndUser__PromptForCred] | o.(EndUser__PromptForCred <: EndUser__PromptForCred__uri) = o.trigger.((UserAgent__InitFlow <: UserAgent__InitFlow__redirect))
	all o : this.sends[AuthServer__ReqAuth] | triggeredBy[o,UserAgent__EnterCred]
	all o : this.sends[AuthServer__ReqAuth] | o.(AuthServer__ReqAuth <: AuthServer__ReqAuth__cred) = o.trigger.((UserAgent__EnterCred <: UserAgent__EnterCred__cred))
	all o : this.sends[AuthServer__ReqAuth] | o.(AuthServer__ReqAuth <: AuthServer__ReqAuth__uri) = o.trigger.((UserAgent__EnterCred <: UserAgent__EnterCred__uri))
	all o : this.sends[ClientServer__SendAuthResp] | triggeredBy[o,UserAgent__Redirect]
	all o : this.sends[ClientServer__SendAuthResp] | o.(ClientServer__SendAuthResp <: ClientServer__SendAuthResp__uri) = o.trigger.((UserAgent__Redirect <: UserAgent__Redirect__uri))
	(some (ClientServer.ClientServer__id & UserAgent__knownClients))
}

-- module ClientServer
one sig ClientServer extends Module {
	ClientServer__addr : lone URI,
	ClientServer__id : lone ClientID,
	ClientServer__scope : lone Scope,
}{
	all o : this.sends[UserAgent__InitFlow] | o.(UserAgent__InitFlow <: UserAgent__InitFlow__redirect) = ClientServer__addr
}

-- module AuthServer
one sig AuthServer extends Module {
	AuthServer__authGrants : Credential some -> lone AuthGrant,
	AuthServer__accessTokens : AuthGrant some -> lone AccessToken,
}{
	all o : this.receives[AuthServer__ReqAuth] | (some AuthServer__authGrants[arg[o.(AuthServer__ReqAuth <: AuthServer__ReqAuth__cred)]])
	all o : this.receives[AuthServer__ReqAccessToken] | (some AuthServer__accessTokens[arg[o.(AuthServer__ReqAccessToken <: AuthServer__ReqAccessToken__authGrant)]])
	all o : this.sends[UserAgent__Redirect] | triggeredBy[o,AuthServer__ReqAuth]
	all o : this.sends[UserAgent__Redirect] | (o.(UserAgent__Redirect <: UserAgent__Redirect__uri).URI__addr = o.trigger.((AuthServer__ReqAuth <: AuthServer__ReqAuth__uri)).URI__addr and (some (o.(UserAgent__Redirect <: UserAgent__Redirect__uri).URI__params & AuthServer__authGrants[o.trigger.((AuthServer__ReqAuth <: AuthServer__ReqAuth__cred))])))
	all o : this.sends[ClientServer__SendAccessToken] | triggeredBy[o,AuthServer__ReqAccessToken]
	all o : this.sends[ClientServer__SendAccessToken] | o.(ClientServer__SendAccessToken <: ClientServer__SendAccessToken__token) = AuthServer__accessTokens[o.trigger.((AuthServer__ReqAccessToken <: AuthServer__ReqAccessToken__authGrant))]
}

-- module ResourceServer
one sig ResourceServer extends Module {
	ResourceServer__resources : AccessToken some -> lone Resource,
}{
	all o : this.receives[ResourceServer__ReqResource] | (some ResourceServer__resources[arg[o.(ResourceServer__ReqResource <: ResourceServer__ReqResource__accessToken)]])
	all o : this.sends[ClientServer__SendResource] | triggeredBy[o,ResourceServer__ReqResource]
	all o : this.sends[ClientServer__SendResource] | o.(ClientServer__SendResource <: ClientServer__SendResource__res) = ResourceServer__resources[o.trigger.((ResourceServer__ReqResource <: ResourceServer__ReqResource__accessToken))]
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = EndUser + UserAgent + ClientServer + AuthServer + ResourceServer
}

-- operation EndUser__PromptForCred
sig EndUser__PromptForCred extends Op {
	EndUser__PromptForCred__uri : lone URI,
}{
	args = EndUser__PromptForCred__uri
	sender in UserAgent
	receiver in EndUser
}

-- operation UserAgent__InitFlow
sig UserAgent__InitFlow extends Op {
	UserAgent__InitFlow__redirect : lone URI,
	UserAgent__InitFlow__id : lone ClientID,
	UserAgent__InitFlow__scope : lone Scope,
}{
	args = UserAgent__InitFlow__redirect + UserAgent__InitFlow__id + UserAgent__InitFlow__scope
	sender in ClientServer
	receiver in UserAgent
}

-- operation UserAgent__EnterCred
sig UserAgent__EnterCred extends Op {
	UserAgent__EnterCred__cred : lone Credential,
	UserAgent__EnterCred__uri : lone URI,
}{
	args = UserAgent__EnterCred__cred + UserAgent__EnterCred__uri
	sender in EndUser
	receiver in UserAgent
}

-- operation UserAgent__Redirect
sig UserAgent__Redirect extends Op {
	UserAgent__Redirect__uri : lone URI,
}{
	args = UserAgent__Redirect__uri
	sender in AuthServer
	receiver in UserAgent
}

-- operation ClientServer__SendAuthResp
sig ClientServer__SendAuthResp extends Op {
	ClientServer__SendAuthResp__uri : lone URI,
}{
	args = ClientServer__SendAuthResp__uri
	sender in UserAgent
	receiver in ClientServer
}

-- operation ClientServer__SendAccessToken
sig ClientServer__SendAccessToken extends Op {
	ClientServer__SendAccessToken__token : lone AccessToken,
}{
	args = ClientServer__SendAccessToken__token
	sender in AuthServer
	receiver in ClientServer
}

-- operation ClientServer__SendResource
sig ClientServer__SendResource extends Op {
	ClientServer__SendResource__res : lone Resource,
}{
	args = ClientServer__SendResource__res
	sender in ResourceServer
	receiver in ClientServer
}

-- operation AuthServer__ReqAuth
sig AuthServer__ReqAuth extends Op {
	AuthServer__ReqAuth__cred : lone Credential,
	AuthServer__ReqAuth__uri : lone URI,
}{
	args = AuthServer__ReqAuth__cred + AuthServer__ReqAuth__uri
	sender in UserAgent
	receiver in AuthServer
}

-- operation AuthServer__ReqAccessToken
sig AuthServer__ReqAccessToken extends Op {
	AuthServer__ReqAccessToken__authGrant : lone AuthGrant,
}{
	args = AuthServer__ReqAccessToken__authGrant
	sender in ClientServer
	receiver in AuthServer
}

-- operation ResourceServer__ReqResource
sig ResourceServer__ReqResource extends Op {
	ResourceServer__ReqResource__accessToken : lone AccessToken,
}{
	args = ResourceServer__ReqResource__accessToken
	sender in ClientServer
	receiver in ResourceServer
}

-- fact dataFacts
fact dataFacts {
	creates.AuthGrant in AuthServer
	creates.Credential in EndUser
	creates.AccessToken in AuthServer
	creates.Resource in ResourceServer
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
	URI__addr : lone Addr,
	URI__params : set Payload,
}{
	fields = URI__addr + URI__params
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
