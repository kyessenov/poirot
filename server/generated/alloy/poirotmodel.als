open libraryWeb/webbasic
open libraryWeb/redirect

-- module MyStore
one sig MyStore extends HttpServer {
	MyStore__passwords : (UserID set -> lone Password) -> set Op,
	MyStore__sessions : (UserID set -> lone SessionID) -> set Op,
	MyStore__orders : (UserID set -> lone OrderID) -> set Op,
}{
	all o : this.receives[MyStore__Signup] | MyStore__passwords.(o.next) = (MyStore__passwords.o + ((o.MyStore__Signup__uid) -> (o.MyStore__Signup__pwd)))
	all o : this.receives[MyStore__Login] | ((o.MyStore__Login__pwd) = MyStore__passwords.o[(o.MyStore__Login__uid)] and (o.MyStore__Login__ret) = MyStore__sessions.o[(o.MyStore__Login__uid)])
	all o : this.receives[MyStore__PlaceOrder] | MyStore__orders.(o.next) = (MyStore__orders.o + ((o.MyStore__PlaceOrder__uid) -> (o.MyStore__PlaceOrder__oid)))
	all o : this.receives[MyStore__ListOrder] | (o.MyStore__ListOrder__ret) = MyStore__orders.o[(o.MyStore__ListOrder__uid)]
	(contains[(MyStore__passwords.first), Customer__myId, Customer__myPwd] and uniquelyAssigned[(MyStore__orders.first)])
	all o : Op - last | let o' = o.next | MyStore__passwords.o' != MyStore__passwords.o implies (o in MyStore__Signup & SuccessOp and o.receiver = this)
	all o : Op - last | let o' = o.next | MyStore__orders.o' != MyStore__orders.o implies (o in MyStore__PlaceOrder & SuccessOp and o.receiver = this)
	all o : Op - last | let o' = o.next | MyStore__sessions.o' = MyStore__sessions.o
	this.initAccess in this.MyStoreInitData
	this.MyStoreFieldData in this.initAccess
}
fun MyStoreFieldData[m : Module] : set Data {
	UserID.((m.MyStore__passwords).first) + ((m.MyStore__passwords).first).Password + UserID.((m.MyStore__sessions).first) + ((m.MyStore__sessions).first).SessionID + UserID.((m.MyStore__orders).first) + ((m.MyStore__orders).first).OrderID
}
fun MyStoreInitData[m : Module] : set Data {
	NonCriticalData + UserID.((m.MyStore__passwords).first) + ((m.MyStore__passwords).first).Password + UserID.((m.MyStore__sessions).first) + ((m.MyStore__sessions).first).SessionID + UserID.((m.MyStore__orders).first) + ((m.MyStore__orders).first).OrderID
}

-- module Customer
one sig Customer extends Browser {
	Customer__myId : one UserID,
	Customer__myPwd : one Password,
}{
	this.initAccess in this.CustomerInitData
	this.CustomerFieldData in this.initAccess
}
fun CustomerFieldData[m : Module] : set Data {
	(m.Customer__myId) + (m.Customer__myPwd)
}
fun CustomerInitData[m : Module] : set Data {
	NonCriticalData + (m.Customer__myId) + (m.Customer__myPwd)
}

-- module EvilServer
one sig EvilServer extends HttpServer {
}{
	this.initAccess in this.EvilServerInitData
}
fun EvilServerInitData[m : Module] : set Data {
	Data - (ConfidentialData + (CriticalData & TrustedModule.initAccess))
}

-- module EvilClient
one sig EvilClient extends Browser {
}{
	this.initAccess in this.EvilClientInitData
}
fun EvilClientInitData[m : Module] : set Data {
	Data - (ConfidentialData + (CriticalData & TrustedModule.initAccess))
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = MyStore + Customer
}

-- operation MyStore__Signup
sig MyStore__Signup in HTTPReq {
	MyStore__Signup__uid : one UserID,
	MyStore__Signup__pwd : one Password,
}{
	args = MyStore__Signup__uid + MyStore__Signup__pwd
	no ret
	TrustedModule & sender in Customer
	TrustedModule & receiver in MyStore
}

-- operation MyStore__Login
sig MyStore__Login in HTTPReq {
	MyStore__Login__uid : one UserID,
	MyStore__Login__pwd : one Password,
	MyStore__Login__ret : one SessionID,
}{
	args = MyStore__Login__uid + MyStore__Login__pwd
	ret = MyStore__Login__ret
	TrustedModule & sender in Customer
	TrustedModule & receiver in MyStore
}

-- operation MyStore__PlaceOrder
sig MyStore__PlaceOrder in HTTPReq {
	MyStore__PlaceOrder__uid : one UserID,
	MyStore__PlaceOrder__oid : one OrderID,
}{
	args = MyStore__PlaceOrder__uid + MyStore__PlaceOrder__oid
	no ret
	TrustedModule & sender in Customer
	TrustedModule & receiver in MyStore
}

-- operation MyStore__ListOrder
sig MyStore__ListOrder in HTTPReq {
	MyStore__ListOrder__uid : one UserID,
	MyStore__ListOrder__ret : one OrderID,
}{
	args = MyStore__ListOrder__uid
	ret = MyStore__ListOrder__ret
	TrustedModule & sender in Customer
	TrustedModule & receiver in MyStore
}

-- operation EvilServer__EvilHttpReq
sig EvilServer__EvilHttpReq in HTTPReq {
	EvilServer__EvilHttpReq__in : set Data,
	EvilServer__EvilHttpReq__ret : one Data,
}{
	args = EvilServer__EvilHttpReq__in
	ret = EvilServer__EvilHttpReq__ret
	TrustedModule & receiver in EvilServer
}

-- datatype declarations
sig UserID extends Data {
}
sig OrderID extends Data {
}
sig SessionID extends Data {
}
sig Password extends Data {
}
sig OtherData extends Data {}

-- fact criticalDataFacts
fact criticalDataFacts {
	(SessionID + Password) & TrustedModule.initAccess in CriticalData
}

-- fact operationList
fact operationList {
	Op = MyStore__Signup + MyStore__Login + MyStore__PlaceOrder + MyStore__ListOrder + EvilServer__EvilHttpReq
	disjointOps[MyStore__Signup, MyStore__Login]
	disjointOps[MyStore__Signup, MyStore__PlaceOrder]
	disjointOps[MyStore__Signup, MyStore__ListOrder]
	disjointOps[MyStore__Signup, EvilServer__EvilHttpReq]
	disjointOps[MyStore__Login, MyStore__PlaceOrder]
	disjointOps[MyStore__Login, MyStore__ListOrder]
	disjointOps[MyStore__Login, EvilServer__EvilHttpReq]
	disjointOps[MyStore__PlaceOrder, MyStore__ListOrder]
	disjointOps[MyStore__PlaceOrder, EvilServer__EvilHttpReq]
	disjointOps[MyStore__ListOrder, EvilServer__EvilHttpReq]
}
pred myPolicy {
confidential[(MyStore__orders.Op), Customer__myId]
}


fact GenericFacts {
  Op in SuccessOp
  all o : Op | 
    (o.sender in TrustedModule and some o.args & CriticalData) implies 
      o.receiver in TrustedModule
  all o : Op |
    (o.sender in TrustedModule & HttpServer) implies
       o.receiver not in UntrustedModule & HttpServer
  (no (SuccessOp - last) & EvilServer__EvilHttpReq implies no sender.EvilServer)
}
check myPolicy2 { myPolicy } for 1 but 8 Data, 2 Op, 2 Step, 4 Module

check myPolicy3 { myPolicy } for 1 but 8 Data, 3 Op, 3 Step, 4 Module

check myPolicy4 { myPolicy } for 1 but 8 Data, 4 Op, 4 Step, 4 Module

check myPolicy5 { myPolicy } for 1 but 8 Data, 5 Op, 5 Step, 4 Module

check myPolicy6 { myPolicy } for 1 but 8 Data, 6 Op, 6 Step, 4 Module

check myPolicy7 { myPolicy } for 1 but 8 Data, 7 Op, 7 Step, 4 Module

run SanityCheck {
  some o : MyStore__Signup & SuccessOp
 | o != last  some o : MyStore__Login & SuccessOp
 | o != last  some o : MyStore__PlaceOrder & SuccessOp
 | o != last  some o : MyStore__ListOrder & SuccessOp
 | o != last  no (receiver + sender).UntrustedModule & SuccessOp
} for 1 but 8 Data, 5 Op, 5 Step, 4 Module


check Confidentiality {
  Confidentiality
} for 1 but 8 Data, 5 Op, 5 Step, 4 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 1 but 8 Data, 5 Op, 5 Step, 4 Module

fun RelevantData : Data -> Step {
	{ d : Data, s : Step | 
		some m : Module | 
			m-> d -> s in this/receives
	}
}
fun talksTo : Module -> Module -> Step {
	{from, to : Module, s : Step | from = s.o.sender and to = s.o.receiver }
}
fun RelevantOp : Op -> Step {
	{ o' : SuccessOp, s : Step |
		o' = s.o
	}
}
fun receives : Module -> Data -> Step {
	{ m : Module, d : Data, s : Step | 
		(m = s.o.receiver and d in s.o.args) or (m = s.o.sender and d in s.o.ret)}
}
