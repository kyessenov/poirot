open generic/basic

-- module MyStore
one sig MyStore extends Module {
	MyStore__userCreds : UID set -> lone Cred,
	MyStore__orders : (UID set -> lone PID) -> set Step,
}{
	all o : this.receives[MyStore__Login] | o.(MyStore__Login <: MyStore__Login__cred) = MyStore__userCreds[o.(MyStore__Login <: MyStore__Login__uid)]
	this.initAccess in NonCriticalData + UID.MyStore__userCreds + MyStore__userCreds.Cred + UID.(MyStore__orders.first) + (MyStore__orders.first).PID
}

-- module Customer
one sig Customer extends Module {
	Customer__id : one UID,
	Customer__cred : one Cred,
}{
	this.initAccess in NonCriticalData + Customer__id + Customer__cred
}


-- operation MyStore__Login
sig MyStore__Login extends Op {
	MyStore__Login__uid : one UID,
	MyStore__Login__cred : one Cred,
}{
	args in MyStore__Login__uid + MyStore__Login__cred
	no ret
	sender in Customer
	receiver in MyStore
}

-- datatype declarations
sig UID extends Data {
}
sig PID extends Data {
}
sig Cred extends Data {
}
sig OtherData extends Data {}

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
