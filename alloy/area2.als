open models/basic
open models/crypto[Data]

-- module A2Site
one sig A2Site extends Module {
	A2Site__profiles : UserID set -> lone Profile,
	A2Site__userType : UserID set -> lone UserType,
}{
	all o : this.receives[A2Site__ViewProfile] | 
		(
			((A2Site__userType[o.(A2Site__ViewProfile <: A2Site__ViewProfile__token).Token__encodes] = TypeStudent and o.(A2Site__ViewProfile <: A2Site__ViewProfile__ret).Profile__id = o.(A2Site__ViewProfile <: A2Site__ViewProfile__token).Token__encodes)
			or
			A2Site__userType[o.(A2Site__ViewProfile <: A2Site__ViewProfile__token).Token__encodes] = TypeFaculty
			)
		or
		A2Site__userType[o.(A2Site__ViewProfile <: A2Site__ViewProfile__token).Token__encodes] = TypeAdmin
		)
	all o : this.receives[A2Site__ViewProfile] | o.(A2Site__ViewProfile <: A2Site__ViewProfile__ret) = A2Site__profiles[o.(A2Site__ViewProfile <: A2Site__ViewProfile__uid)]
	(all uid : UserID | (all p : Profile | ((some (A2Site__profiles & uid -> p)) implies p.Profile__id = uid)))
	accesses.first in NonCriticalData + UserID.A2Site__profiles + A2Site__profiles.Profile + UserID.A2Site__userType + A2Site__userType.UserType + Token + Profile
}

-- module DirectoryService
one sig DirectoryService extends Module {
	DirectoryService__userRecords : UserRecord set -> set Step,
}{
	all o : this.receives[DirectoryService__GetUserRecords] | o.(DirectoryService__GetUserRecords <: DirectoryService__GetUserRecords__ret) = DirectoryService__userRecords.(o.pre)
	accesses.first in NonCriticalData + (DirectoryService__userRecords.first)
}

-- module Faculty
one sig Faculty extends Module {
	Faculty__id : one UserID,
	Faculty__token : one Token,
}{
	accesses.first in NonCriticalData + Faculty__id + Faculty__token
}

-- module Student
one sig Student extends Module {
	Student__id : one UserID,
	Student__token : one Token,
}{
	accesses.first in NonCriticalData + Student__id + Student__token
}

-- module Admin
one sig Admin extends Module {
	Admin__id : one UserID,
	Admin__token : one Token,
}{
	accesses.first in NonCriticalData + Admin__id + Admin__token
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = A2Site + DirectoryService + Faculty + Admin
}

-- operation A2Site__ViewProfile
sig A2Site__ViewProfile extends Op {
	A2Site__ViewProfile__uid : one UserID,
	A2Site__ViewProfile__token : one Token,
	A2Site__ViewProfile__ret : one Profile,
}{
	args = A2Site__ViewProfile__uid + A2Site__ViewProfile__token
	ret = A2Site__ViewProfile__ret
	sender in Faculty + Student + Admin
	receiver in A2Site
}

-- operation DirectoryService__GetUserRecords
sig DirectoryService__GetUserRecords extends Op {
	DirectoryService__GetUserRecords__ret : set UserRecord,
}{
	no args
	ret = DirectoryService__GetUserRecords__ret
	sender in A2Site
	receiver in DirectoryService
}

-- datatype declarations
sig UserID extends Data {
}{
	no fields
}
sig Token extends Data {
	Token__encodes : one UserID,
}{
	fields = Token__encodes
}
abstract sig UserType extends Data {
}{
}
one sig TypeStudent extends UserType {
}{
	no fields
}
one sig TypeAdmin extends UserType {
}{
	no fields
}
one sig TypeFaculty extends UserType {
}{
	no fields
}
sig UserRecord extends Data {
	UserRecord__id : one UserID,
	UserRecord__typ : one UserType,
}{
	fields = UserRecord__id + UserRecord__typ
}
sig Profile extends Data {
	Profile__id : one UserID,
}{
	fields = Profile__id
}
sig OtherData extends Data {}{ no fields }

-- fact criticalDataFacts
fact criticalDataFacts {
	CriticalData = Token + Profile
}

run SanityCheck {
  some A2Site__ViewProfile & SuccessOp
  some DirectoryService__GetUserRecords & SuccessOp
} for 1 but 7 Data, 7 Step, 6 Op

fun RelevantOp : Op -> Step {
  {o : Op, t : Step | o.post = t and o in SuccessOp}
}
check Confidentiality {
  Confidentiality
} for 1 but 7 Data, 7 Step, 6 Op

-- check who can create CriticalData
check Integrity {
  Integrity
} for 1 but 7 Data, 7 Step, 6 Op
