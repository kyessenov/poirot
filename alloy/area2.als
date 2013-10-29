open models/basic
open models/crypto[Data]

-- module A2Site
one sig A2Site extends Module {
	A2Site__profiles : (StudentID set -> lone Profile) -> set Step,
	A2Site__advisor : StudentID set -> lone FacultyID,
	A2Site__tokens : StudentID set -> lone Token,
}{
	all o : this.receives[A2Site__ViewProfile] | arg[o.(A2Site__ViewProfile <: A2Site__ViewProfile__t)] = A2Site__tokens[arg[o.(A2Site__ViewProfile <: A2Site__ViewProfile__id)]]
	all o : this.receives[A2Site__ViewProfile] | arg[o.(A2Site__ViewProfile <: A2Site__ViewProfile__ret)] = A2Site__profiles.(o.pre)[arg[o.(A2Site__ViewProfile <: A2Site__ViewProfile__id)]]
	all o : this.receives[A2Site__EditProfile] | arg[o.(A2Site__EditProfile <: A2Site__EditProfile__t)] = A2Site__tokens[arg[o.(A2Site__EditProfile <: A2Site__EditProfile__id)]]
	all o : this.receives[A2Site__EditProfile] | A2Site__profiles.(o.post) = (A2Site__profiles.(o.pre) + arg[o.(A2Site__EditProfile <: A2Site__EditProfile__id)] -> arg[o.(A2Site__EditProfile <: A2Site__EditProfile__newProfile)])
	accesses.first in StudentID.(A2Site__profiles.first) + (A2Site__profiles.first).Profile + StudentID.A2Site__advisor + A2Site__advisor.FacultyID + StudentID.A2Site__tokens + A2Site__tokens.Token + Token + Profile
}

-- module Faculty
one sig Faculty extends Module {
	Faculty__id : one FacultyID,
}{
	accesses.first in Faculty__id
}

-- module Student
one sig Student extends Module {
	Student__id : one StudentID,
	Student__token : one Token,
}{
	accesses.first in Student__id + Student__token
}

-- module Admin
one sig Admin extends Module {
}{
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = A2Site + Faculty + Admin
}

-- operation A2Site__ViewProfile
sig A2Site__ViewProfile extends Op {
	A2Site__ViewProfile__id : one StudentID,
	A2Site__ViewProfile__t : one Token,
	A2Site__ViewProfile__ret : one Profile,
}{
	args = A2Site__ViewProfile__id + A2Site__ViewProfile__t
	ret = A2Site__ViewProfile__ret
	sender in Faculty + Student + Admin
	receiver in A2Site
}

-- operation A2Site__EditProfile
sig A2Site__EditProfile extends Op {
	A2Site__EditProfile__id : one StudentID,
	A2Site__EditProfile__t : one Token,
	A2Site__EditProfile__newProfile : one Profile,
}{
	args = A2Site__EditProfile__id + A2Site__EditProfile__t + A2Site__EditProfile__newProfile
	no ret
	sender in Faculty + Student + Admin
	receiver in A2Site
}

-- fact dataFacts
fact dataFacts {
	creates.Profile in A2Site
	creates.Token in A2Site
}

-- datatype declarations
sig Profile extends Data {
}{
	no fields
}
sig Token extends Data {
}{
	no fields
}
sig FacultyID extends Data {
}{
	no fields
}
sig StudentID extends Data {
}{
	no fields
}
sig OtherData extends Data {}{ no fields }

-- fact criticalDataFacts
fact criticalDataFacts {
	CriticalData = Profile
}

run SanityCheck {
  some A2Site__ViewProfile & SuccessOp
  some A2Site__EditProfile & SuccessOp
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
