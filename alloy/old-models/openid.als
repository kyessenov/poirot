open models/basic

-- module EndUser
one sig EndUser extends Module {
	EndUser__id : one Addr,
	EndUser__cred : one Credential,
}{
	all o : this.receives[EndUser__PromptCredential] | o.(EndUser__PromptCredential <: EndUser__PromptCredential__forId) = EndUser__id
	all o : this.sends[UserAgent__EnterCred] | triggeredBy[o,EndUser__PromptCredential]
	all o : this.sends[UserAgent__EnterCred] | o.(UserAgent__EnterCred <: UserAgent__EnterCred__id) = EndUser__cred
	all o : this.sends[UserAgent__EnterCred] | o.(UserAgent__EnterCred <: UserAgent__EnterCred__cred) = EndUser__id
	all o : this.sends[RelyingParty__RequestLogIn] | o.(RelyingParty__RequestLogIn <: RelyingParty__RequestLogIn__id) = EndUser__id
	this.initAccess in NonCriticalData + EndUser__id + EndUser__cred + Credential
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
	this.initAccess in NonCriticalData
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
	this.initAccess in NonCriticalData
}

-- module IdentityProvider
one sig IdentityProvider extends Module {
	IdentityProvider__credentials : Addr set -> lone Credential,
	IdentityProvider__identities : Addr set -> lone OpenId,
}{
	all o : this.receives[IdentityProvider__RequestAuth] | (some IdentityProvider__identities[o.(IdentityProvider__RequestAuth <: IdentityProvider__RequestAuth__id)])
	all o : this.receives[IdentityProvider__ReceiveCred] | (some (IdentityProvider__credentials & o.(IdentityProvider__ReceiveCred <: IdentityProvider__ReceiveCred__id) -> o.(IdentityProvider__ReceiveCred <: IdentityProvider__ReceiveCred__cred)))
	all o : this.receives[IdentityProvider__CheckAuth] | (some (IdentityProvider__identities & o.(IdentityProvider__CheckAuth <: IdentityProvider__CheckAuth__id) -> o.(IdentityProvider__CheckAuth <: IdentityProvider__CheckAuth__openId)))
	all o : this.sends[UserAgent__RequestCredential] | triggeredBy[o,IdentityProvider__RequestAuth]
	all o : this.sends[UserAgent__RequestCredential] | o.(UserAgent__RequestCredential <: UserAgent__RequestCredential__id) = o.trigger.((IdentityProvider__RequestAuth <: IdentityProvider__RequestAuth__id))
	all o : this.sends[UserAgent__ReceiveOpenID] | triggeredBy[o,IdentityProvider__ReceiveCred]
	all o : this.sends[UserAgent__ReceiveOpenID] | o.(UserAgent__ReceiveOpenID <: UserAgent__ReceiveOpenID__id) = o.trigger.((IdentityProvider__ReceiveCred <: IdentityProvider__ReceiveCred__id))
	all o : this.sends[UserAgent__ReceiveOpenID] | o.(UserAgent__ReceiveOpenID <: UserAgent__ReceiveOpenID__openId) = IdentityProvider__identities[o.trigger.((IdentityProvider__ReceiveCred <: IdentityProvider__ReceiveCred__id))]
	all o : this.sends[RelyingParty__AuthVerified] | triggeredBy[o,IdentityProvider__CheckAuth]
	all o : this.sends[RelyingParty__AuthVerified] | o.(RelyingParty__AuthVerified <: RelyingParty__AuthVerified__id) = o.trigger.((IdentityProvider__CheckAuth <: IdentityProvider__CheckAuth__id))
	all o : this.sends[RelyingParty__AuthVerified] | o.(RelyingParty__AuthVerified <: RelyingParty__AuthVerified__openId) = o.trigger.((IdentityProvider__CheckAuth <: IdentityProvider__CheckAuth__openId))
	this.initAccess in NonCriticalData + Addr.IdentityProvider__credentials + IdentityProvider__credentials.Credential + Addr.IdentityProvider__identities + IdentityProvider__identities.OpenId
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = EndUser + UserAgent + RelyingParty + IdentityProvider
}

-- operation EndUser__PromptCredential
sig EndUser__PromptCredential extends Op {
	EndUser__PromptCredential__forId : one Addr,
}{
	args in EndUser__PromptCredential__forId
	no ret
	sender in UserAgent
	receiver in EndUser
}

-- operation UserAgent__RedirectToProvider
sig UserAgent__RedirectToProvider extends Op {
	UserAgent__RedirectToProvider__addr : one Addr,
}{
	args in UserAgent__RedirectToProvider__addr
	no ret
	sender in RelyingParty
	receiver in UserAgent
}

-- operation UserAgent__RequestCredential
sig UserAgent__RequestCredential extends Op {
	UserAgent__RequestCredential__id : one Addr,
}{
	args in UserAgent__RequestCredential__id
	no ret
	sender in IdentityProvider
	receiver in UserAgent
}

-- operation UserAgent__EnterCred
sig UserAgent__EnterCred extends Op {
	UserAgent__EnterCred__id : one Addr,
	UserAgent__EnterCred__cred : one Credential,
}{
	args in UserAgent__EnterCred__id + UserAgent__EnterCred__cred
	no ret
	sender in EndUser
	receiver in UserAgent
}

-- operation UserAgent__ReceiveOpenID
sig UserAgent__ReceiveOpenID extends Op {
	UserAgent__ReceiveOpenID__id : one Addr,
	UserAgent__ReceiveOpenID__openId : one OpenId,
}{
	args in UserAgent__ReceiveOpenID__id + UserAgent__ReceiveOpenID__openId
	no ret
	sender in IdentityProvider
	receiver in UserAgent
}

-- operation UserAgent__LoginSuccessful
sig UserAgent__LoginSuccessful extends Op {
}{
	no args
	no ret
	sender in RelyingParty
	receiver in UserAgent
}

-- operation RelyingParty__RequestLogIn
sig RelyingParty__RequestLogIn extends Op {
	RelyingParty__RequestLogIn__id : one Addr,
}{
	args in RelyingParty__RequestLogIn__id
	no ret
	sender in EndUser
	receiver in RelyingParty
}

-- operation RelyingParty__LogIn
sig RelyingParty__LogIn extends Op {
	RelyingParty__LogIn__id : one Addr,
	RelyingParty__LogIn__openId : one OpenId,
}{
	args in RelyingParty__LogIn__id + RelyingParty__LogIn__openId
	no ret
	sender in UserAgent
	receiver in RelyingParty
}

-- operation RelyingParty__AuthVerified
sig RelyingParty__AuthVerified extends Op {
	RelyingParty__AuthVerified__id : one Addr,
	RelyingParty__AuthVerified__openId : one OpenId,
}{
	args in RelyingParty__AuthVerified__id + RelyingParty__AuthVerified__openId
	no ret
	sender in IdentityProvider
	receiver in RelyingParty
}

-- operation IdentityProvider__RequestAuth
sig IdentityProvider__RequestAuth extends Op {
	IdentityProvider__RequestAuth__id : one Addr,
}{
	args in IdentityProvider__RequestAuth__id
	no ret
	sender in UserAgent
	receiver in IdentityProvider
}

-- operation IdentityProvider__ReceiveCred
sig IdentityProvider__ReceiveCred extends Op {
	IdentityProvider__ReceiveCred__id : one Addr,
	IdentityProvider__ReceiveCred__cred : one Credential,
}{
	args in IdentityProvider__ReceiveCred__id + IdentityProvider__ReceiveCred__cred
	no ret
	sender in UserAgent
	receiver in IdentityProvider
}

-- operation IdentityProvider__CheckAuth
sig IdentityProvider__CheckAuth extends Op {
	IdentityProvider__CheckAuth__id : one Addr,
	IdentityProvider__CheckAuth__openId : one OpenId,
}{
	args in IdentityProvider__CheckAuth__id + IdentityProvider__CheckAuth__openId
	no ret
	sender in RelyingParty
	receiver in IdentityProvider
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
	URI__addr : one Addr,
	URI__params : set Payload,
}{
	fields in URI__addr + URI__params
}
sig OtherData extends Data {}{ no fields }

-- fact criticalDataFacts
fact criticalDataFacts {
	CriticalData = OpenId
}

run SanityCheck {
  some EndUser__PromptCredential & SuccessOp
  some UserAgent__RedirectToProvider & SuccessOp
  some UserAgent__RequestCredential & SuccessOp
  some UserAgent__EnterCred & SuccessOp
  some UserAgent__ReceiveOpenID & SuccessOp
  some UserAgent__LoginSuccessful & SuccessOp
  some RelyingParty__RequestLogIn & SuccessOp
  some RelyingParty__LogIn & SuccessOp
  some RelyingParty__AuthVerified & SuccessOp
  some IdentityProvider__RequestAuth & SuccessOp
  some IdentityProvider__ReceiveCred & SuccessOp
  some IdentityProvider__CheckAuth & SuccessOp
} for 2 but 6 Data, 12 Op, 4 Module


check Confidentiality {
  Confidentiality
} for 2 but 6 Data, 12 Op, 4 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 6 Data, 12 Op, 4 Module
