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
	this.initAccess in NonCriticalData + UserID.FBServer__profileData + FBServer__profileData.ProfileData
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = AdClient + FBClient + FBServer
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

-- operation AdServer__GetAd
sig AdServer__GetAd extends Op {
	AdServer__GetAd__ret : one AdPage,
}{
	no args
	ret in AdServer__GetAd__ret
	sender in AdClient
	receiver in AdServer
}

-- operation FBServer__GetProfile
sig FBServer__GetProfile extends Op {
	FBServer__GetProfile__id : one UserID,
	FBServer__GetProfile__ret : one ProfilePage,
}{
	args in FBServer__GetProfile__id
	ret in FBServer__GetProfile__ret
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
sig UserID {
}
sig OtherData extends Data {}{ no fields }

-- fact criticalDataFacts
fact criticalDataFacts {
	CriticalData = PrivateData
}

run SanityCheck {
  some AdServer__SendInfo & SuccessOp
  some AdServer__GetAd & SuccessOp
  some FBServer__GetProfile & SuccessOp
} for 2 but 5 Data, 4 Step,3 Op, 4 Module


check Confidentiality {
  Confidentiality
} for 2 but 5 Data, 4 Step,3 Op, 4 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 5 Data, 4 Step,3 Op, 4 Module

fun RelevantOp : Op -> Step {
  {o : Op, t : Step | o.pre = t and o in SuccessOp}
}
