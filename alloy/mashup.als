open models/basic

-- module AdClient
one sig AdClient extends Module {
}{
	this.initAccess in NonCriticalData
}

-- module AdServer
one sig AdServer extends Module {
}{
	this.initAccess in NonCriticalData
}

-- module FBClient
one sig FBClient extends Module {
}{
	this.initAccess in NonCriticalData
}

-- module FBServer
one sig FBServer extends Module {
	FBServer__profileData : UserID set -> lone ProfileData,
}{
	all o : this.sends[FBClient__DisplayProfile] | triggeredBy[o,FBServer__GetProfile]
	all o : this.sends[FBClient__DisplayProfile] | (some (FBServer__profileData[o.trigger.((FBServer__GetProfile <: FBServer__GetProfile__id))] & o.(FBClient__DisplayProfile <: FBClient__DisplayProfile__page).ProfilePage__d))
	this.initAccess in NonCriticalData + UserID.FBServer__profileData + FBServer__profileData.ProfileData
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = AdClient + FBClient + FBServer
}

-- operation AdClient__DisplayAd
sig AdClient__DisplayAd extends Op {
	AdClient__DisplayAd__ad : one AdPage,
}{
	args in AdClient__DisplayAd__ad
	no ret
	sender in AdServer
	receiver in AdClient
}

-- operation AdServer__SendInfo
sig AdServer__SendInfo extends Op {
	AdServer__SendInfo__d : one ProfileData,
}{
	args in AdServer__SendInfo__d
	no ret
	sender in AdClient
	receiver in AdServer
}

-- operation FBClient__DisplayProfile
sig FBClient__DisplayProfile extends Op {
	FBClient__DisplayProfile__page : one ProfilePage,
}{
	args in FBClient__DisplayProfile__page
	no ret
	sender in FBServer
	receiver in FBClient
}

-- operation FBServer__GetProfile
sig FBServer__GetProfile extends Op {
	FBServer__GetProfile__id : one UserID,
}{
	args in FBServer__GetProfile__id
	no ret
	sender in FBClient
	receiver in FBServer
}

-- datatype declarations
sig AdPage extends Data {
}{
	no fields
}
abstract sig ProfileData extends Data {
}{
}
sig PrivateData extends ProfileData {
}{
	no fields
}
sig PublicData extends ProfileData {
}{
	no fields
}
sig ProfilePage extends Data {
	ProfilePage__d : set ProfileData,
}{
	fields in ProfilePage__d
}
sig UserID extends Data {
}{
	no fields
}
sig OtherData extends Data {}{ no fields }

-- fact criticalDataFacts
fact criticalDataFacts {
	CriticalData = PrivateData
}

run SanityCheck {
  some AdClient__DisplayAd & SuccessOp
  some AdServer__SendInfo & SuccessOp
  some FBClient__DisplayProfile & SuccessOp
  some FBServer__GetProfile & SuccessOp
} for 2 but 6 Data, 5 Step,4 Op, 4 Module


check Confidentiality {
  Confidentiality
} for 2 but 6 Data, 5 Step,4 Op, 4 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 6 Data, 5 Step,4 Op, 4 Module
fun RelevantOp : Op -> Step {
  {o : Op, t : Step | o.post = t and o in SuccessOp}
}
