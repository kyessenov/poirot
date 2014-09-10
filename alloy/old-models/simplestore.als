open models/basic

-- module MyStore
one sig MyStore extends Module {
	MyStore__userCreds : UID set -> lone Cred,
	MyStore__orders : (UID set -> lone PID) -> set Step,
}{
	all o : this.receives[MyStore__Login] | o.(MyStore__Login <: MyStore__Login__cred) = MyStore__userCreds[o.(MyStore__Login <: MyStore__Login__uid)]
	this.initAccess in NonCriticalData + UID.MyStore__userCreds + MyStore__userCreds.Cred + UID.(MyStore__orders.first) + (MyStore__orders.first).PID
}

-- module Student
one sig Student extends Module {
	Student__id : one UID,
	Student__cred : one Cred,
}{
	this.initAccess in NonCriticalData + Student__id + Student__cred
}


-- operation MyStore__Login
sig MyStore__Login extends Op {
	MyStore__Login__uid : one UID,
	MyStore__Login__cred : one Cred,
}{
	args in MyStore__Login__uid + MyStore__Login__cred
	no ret
	sender in Student
	receiver in MyStore
}

-- datatype declarations
sig UID extends Data {
}{
	no fields
}
sig PID extends Data {
}{
	no fields
}
sig Cred extends Data {
}{
	no fields
}
sig OtherData extends Data {}{ no fields }

run SanityCheck {
  some MyStore__Login & SuccessOp
} for 2 but 3 Data, 1 Op, 2 Module


check Confidentiality {
  Confidentiality
} for 2 but 3 Data, 1 Op, 2 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 3 Data, 1 Op, 2 Module
