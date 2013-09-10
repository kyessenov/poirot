open models/basic
open models/crypto[Data]

-- module EndUser
one sig EndUser extends Module {
	EndUser__id : lone Addr,
	EndUser__cred : lone Credential,
}{
	all o : this.receives[EndUser__PromptCredential] | arg[o.(EndUser__PromptCredential <: EndUser__PromptCredential__forId)] = EndUser__id
	all o : this.sends[UserAgent__EnterCred] | triggeredBy[o,EndUser__PromptCredential]
	all o : this.sends[UserAgent__EnterCred] | o.(UserAgent__EnterCred <: UserAgent__EnterCred__id) = EndUser__cred
	all o : this.sends[UserAgent__EnterCred] | o.(UserAgent__EnterCred <: UserAgent__EnterCred__cred) = EndUser__id
	all o : this.sends[RelyingParty__RequestLogIn] | o.(RelyingParty__RequestLogIn <: RelyingParty__RequestLogIn__id) = EndUser__id
}

-- module UserAgent
one sig UserAgent extends Module {
}{
	all o : this.sends[IdentityProvider__RequestAuth] | triggeredBy[o,UserAgent__RedirectToProvider]
	all o : this.sends[IdentityProvider__RequestAuth] | o.(IdentityProvider__RequestAuth <: IdentityProvider__RequestAuth__id) = o.trigger.((UserAgent__RedirectToProvider <: UserAgent__RedirectToProvider__addr))
	all o : this.sends[EndUser__PromptCredential] | triggeredBy[o,UserAgent__RequestCredential]
	all o : this.sends[EndUser__PromptCredential] | o.(EndUser__PromptCredential <: EndUser__PromptCredential__forId) = o.trigger.((UserAgent__RequestCredential <: UserAgent__RequestCredential__id))
	all o : this.sends[IdentityProvider__ReceiveCred] | triggeredBy[o,UserAgent__EnterCred]
	all o : this.sends[IdentityProvider__ReceiveCred] | o.(IdentityProvider__ReceiveCred <: IdentityProvider__ReceiveCred__id) = o.trigger.((UserAgent__EnterCred <: UserAgent__EnterCred__id))
	all o : this.sends[IdentityProvider__ReceiveCred] | o.(IdentityProvider__ReceiveCred <: IdentityProvider__ReceiveCred__cred) = o.trigger.((UserAgent__EnterCred <: UserAgent__EnterCred__cred))
	all o : this.sends[RelyingParty__LogIn] | triggeredBy[o,UserAgent__ReceiveOpenID]
	all o : this.sends[RelyingParty__LogIn] | o.(RelyingParty__LogIn <: RelyingParty__LogIn__id) = o.trigger.((UserAgent__ReceiveOpenID <: UserAgent__ReceiveOpenID__id))
	all o : this.sends[RelyingParty__LogIn] | o.(RelyingParty__LogIn <: RelyingParty__LogIn__openId) = o.trigger.((UserAgent__ReceiveOpenID <: UserAgent__ReceiveOpenID__openId))
}

-- module RelyingParty
one sig RelyingParty extends Module {
}{
	all o : this.sends[UserAgent__RedirectToProvider] | triggeredBy[o,RelyingParty__RequestLogIn]
	all o : this.sends[UserAgent__RedirectToProvider] | o.(UserAgent__RedirectToProvider <: UserAgent__RedirectToProvider__addr) = o.trigger.((RelyingParty__RequestLogIn <: RelyingParty__RequestLogIn__id))
	all o : this.sends[IdentityProvider__CheckAuth] | triggeredBy[o,RelyingParty__LogIn]
	all o : this.sends[IdentityProvider__CheckAuth] | o.(IdentityProvider__CheckAuth <: IdentityProvider__CheckAuth__id) = o.trigger.((RelyingParty__LogIn <: RelyingParty__LogIn__id))
	all o : this.sends[IdentityProvider__CheckAuth] | o.(IdentityProvider__CheckAuth <: IdentityProvider__CheckAuth__openId) = o.trigger.((RelyingParty__LogIn <: RelyingParty__LogIn__openId))
	all o : this.sends[UserAgent__LoginSuccessful] | triggeredBy[o,RelyingParty__AuthVerified]
}

-- module IdentityProvider
one sig IdentityProvider extends Module {
	IdentityProvider__credentials : Addr -> Credential,
	IdentityProvider__identities : Addr -> OpenId,
}{
	all o : this.receives[IdentityProvider__RequestAuth] | (some IdentityProvider__identities[arg[o.(IdentityProvider__RequestAuth <: IdentityProvider__RequestAuth__id)]])
	all o : this.receives[IdentityProvider__ReceiveCred] | (some (IdentityProvider__credentials & arg[o.(IdentityProvider__ReceiveCred <: IdentityProvider__ReceiveCred__id)] -> arg[o.(IdentityProvider__ReceiveCred <: IdentityProvider__ReceiveCred__cred)]))
	all o : this.receives[IdentityProvider__CheckAuth] | (some (IdentityProvider__identities & arg[o.(IdentityProvider__CheckAuth <: IdentityProvider__CheckAuth__id)] -> arg[o.(IdentityProvider__CheckAuth <: IdentityProvider__CheckAuth__openId)]))
	all o : this.sends[UserAgent__RequestCredential] | triggeredBy[o,IdentityProvider__RequestAuth]
	all o : this.sends[UserAgent__RequestCredential] | o.(UserAgent__RequestCredential <: UserAgent__RequestCredential__id) = o.trigger.((IdentityProvider__RequestAuth <: IdentityProvider__RequestAuth__id))
	all o : this.sends[UserAgent__ReceiveOpenID] | triggeredBy[o,IdentityProvider__ReceiveCred]
	all o : this.sends[UserAgent__ReceiveOpenID] | o.(UserAgent__ReceiveOpenID <: UserAgent__ReceiveOpenID__id) = o.trigger.((IdentityProvider__ReceiveCred <: IdentityProvider__ReceiveCred__id))
	all o : this.sends[UserAgent__ReceiveOpenID] | o.(UserAgent__ReceiveOpenID <: UserAgent__ReceiveOpenID__openId) = o.trigger.((IdentityProvider__ReceiveCred <: IdentityProvider__ReceiveCred__id)).IdentityProvider__identities
	all o : this.sends[RelyingParty__AuthVerified] | triggeredBy[o,IdentityProvider__CheckAuth]
	all o : this.sends[RelyingParty__AuthVerified] | o.(RelyingParty__AuthVerified <: RelyingParty__AuthVerified__id) = o.trigger.((IdentityProvider__CheckAuth <: IdentityProvider__CheckAuth__id))
	all o : this.sends[RelyingParty__AuthVerified] | o.(RelyingParty__AuthVerified <: RelyingParty__AuthVerified__openId) = o.trigger.((IdentityProvider__CheckAuth <: IdentityProvider__CheckAuth__openId))
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = EndUser + UserAgent + RelyingParty + IdentityProvider
}

-- operation EndUser__PromptCredential
sig EndUser__PromptCredential extends Op {
	EndUser__PromptCredential__forId : lone Addr,
}{
	args = EndUser__PromptCredential__forId
	sender in UserAgent
	receiver in EndUser
}

-- operation UserAgent__RedirectToProvider
sig UserAgent__RedirectToProvider extends Op {
	UserAgent__RedirectToProvider__addr : lone Addr,
}{
	args = UserAgent__RedirectToProvider__addr
	sender in RelyingParty
	receiver in UserAgent
}

-- operation UserAgent__RequestCredential
sig UserAgent__RequestCredential extends Op {
	UserAgent__RequestCredential__id : lone Addr,
}{
	args = UserAgent__RequestCredential__id
	sender in IdentityProvider
	receiver in UserAgent
}

-- operation UserAgent__EnterCred
sig UserAgent__EnterCred extends Op {
	UserAgent__EnterCred__id : lone Addr,
	UserAgent__EnterCred__cred : lone Credential,
}{
	args = UserAgent__EnterCred__id + UserAgent__EnterCred__cred
	sender in EndUser
	receiver in UserAgent
}

-- operation UserAgent__ReceiveOpenID
sig UserAgent__ReceiveOpenID extends Op {
	UserAgent__ReceiveOpenID__id : lone Addr,
	UserAgent__ReceiveOpenID__openId : lone OpenId,
}{
	args = UserAgent__ReceiveOpenID__id + UserAgent__ReceiveOpenID__openId
	sender in IdentityProvider
	receiver in UserAgent
}

-- operation UserAgent__LoginSuccessful
sig UserAgent__LoginSuccessful extends Op {
}{
	no args
	sender in RelyingParty
	receiver in UserAgent
}

-- operation RelyingParty__RequestLogIn
sig RelyingParty__RequestLogIn extends Op {
	RelyingParty__RequestLogIn__id : lone Addr,
}{
	args = RelyingParty__RequestLogIn__id
	sender in EndUser
	receiver in RelyingParty
}

-- operation RelyingParty__LogIn
sig RelyingParty__LogIn extends Op {
	RelyingParty__LogIn__id : lone Addr,
	RelyingParty__LogIn__openId : lone OpenId,
}{
	args = RelyingParty__LogIn__id + RelyingParty__LogIn__openId
	sender in UserAgent
	receiver in RelyingParty
}

-- operation RelyingParty__AuthVerified
sig RelyingParty__AuthVerified extends Op {
	RelyingParty__AuthVerified__id : lone Addr,
	RelyingParty__AuthVerified__openId : lone OpenId,
}{
	args = RelyingParty__AuthVerified__id + RelyingParty__AuthVerified__openId
	sender in IdentityProvider
	receiver in RelyingParty
}

-- operation IdentityProvider__RequestAuth
sig IdentityProvider__RequestAuth extends Op {
	IdentityProvider__RequestAuth__id : lone Addr,
}{
	args = IdentityProvider__RequestAuth__id
	sender in UserAgent
	receiver in IdentityProvider
}

-- operation IdentityProvider__ReceiveCred
sig IdentityProvider__ReceiveCred extends Op {
	IdentityProvider__ReceiveCred__id : lone Addr,
	IdentityProvider__ReceiveCred__cred : lone Credential,
}{
	args = IdentityProvider__ReceiveCred__id + IdentityProvider__ReceiveCred__cred
	sender in UserAgent
	receiver in IdentityProvider
}

-- operation IdentityProvider__CheckAuth
sig IdentityProvider__CheckAuth extends Op {
	IdentityProvider__CheckAuth__id : lone Addr,
	IdentityProvider__CheckAuth__openId : lone OpenId,
}{
	args = IdentityProvider__CheckAuth__id + IdentityProvider__CheckAuth__openId
	sender in RelyingParty
	receiver in IdentityProvider
}

-- fact dataFacts
fact dataFacts {
	creates.Payload in EndUser
	creates.Credential in EndUser
	no creates.OpenId
}

-- datatype declarations
abstract sig Payload extends Data {
}{
}
sig Credential extends Payload {
}{
	no fields
}
sig OpenId extends Payload {
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
	URI__addr : lone Addr,
	URI__params : set Payload,
}{
	fields = URI__addr + URI__params
}
sig OtherData extends Data {}{ no fields }

-- fact criticalDataFacts
fact criticalDataFacts {
	CriticalData = OpenId
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
