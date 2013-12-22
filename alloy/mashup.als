open models/basic
open models/crypto[Data]

-- module AdClient
one sig AdClient extends Module {
}{
	accesses.first in NonCriticalData
}

-- module AdServer
one sig AdServer extends Module {
}{
	accesses.first in NonCriticalData
}

-- module FBClient
one sig FBClient extends Module {
}{
	accesses.first in NonCriticalData
}

-- module FBServer
one sig FBServer extends Module {
}{
	accesses.first in NonCriticalData
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = FBClient + FBServer
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
	FBClient__DisplayProfile__p : one ProfileData,
}{
	args in FBClient__DisplayProfile__p
	no ret
	sender in FBServer
	receiver in FBClient
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
sig OtherData extends Data {}{ no fields }

run SanityCheck {
  some AdClient__DisplayAd & SuccessOp
  some AdServer__SendInfo & SuccessOp
  some FBClient__DisplayProfile & SuccessOp
} for 1 but 4 Data, 4 Step,3 Op, 4 Module


fun RelevantOp : Op -> Step {
  {o : Op, t : Step | o.post = t and o in SuccessOp}
}
check Confidentiality {
  Confidentiality
} for 1 but 4 Data, 4 Step,3 Op, 4 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 1 but 4 Data, 4 Step,3 Op, 4 Module

