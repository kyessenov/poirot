open libraryWeb/WebBasic
open libraryWeb/Redirect

-- module MyStore
one sig MyStore extends HttpServer {
	MyStore__passwords : UserID set -> lone Password,
	MyStore__sessions : UserID set -> lone SessionID,
	MyStore__orders : (UserID set -> lone OrderID) -> set Op,
}{
	all o : this.receives[MyStore__Login] | ((o.MyStore__Login__pwd) = MyStore__passwords[(o.MyStore__Login__uid)] and (o.MyStore__Login__ret) = MyStore__sessions[(o.MyStore__Login__uid)])
	all o : this.receives[MyStore__PlaceOrder] | MyStore__orders.(o.next) = (MyStore__orders.o + ((o.MyStore__PlaceOrder__uid) -> (o.MyStore__PlaceOrder__oid)))
	all o : this.receives[MyStore__ListOrder] | (o.MyStore__ListOrder__ret) = MyStore__orders.o[(o.MyStore__ListOrder__uid)]
	all o : Op - last | let o' = o.next | MyStore__orders.o' != MyStore__orders.o implies o in MyStore__PlaceOrder & SuccessOp
	this.initAccess in NonCriticalData + UserID.MyStore__passwords + MyStore__passwords.Password + UserID.MyStore__sessions + MyStore__sessions.SessionID + UserID.(MyStore__orders.first) + (MyStore__orders.first).OrderID
}

-- module Customer
one sig Customer extends Browser {
	Customer__myId : one UserID,
	Customer__myPwd : one Password,
}{
	this.initAccess in NonCriticalData + Customer__myId + Customer__myPwd
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = MyStore + Customer
}

-- operation MyStore__Login
sig MyStore__Login extends Op {
	MyStore__Login__uid : one UserID,
	MyStore__Login__pwd : one Password,
	MyStore__Login__ret : one SessionID,
}{
	args in MyStore__Login__uid + MyStore__Login__pwd
	ret in MyStore__Login__ret
	TrustedModule & sender in Customer
	TrustedModule & receiver in MyStore
}

-- operation MyStore__PlaceOrder
sig MyStore__PlaceOrder extends Op {
	MyStore__PlaceOrder__uid : one UserID,
	MyStore__PlaceOrder__oid : one OrderID,
}{
	args in MyStore__PlaceOrder__uid + MyStore__PlaceOrder__oid
	no ret
	TrustedModule & sender in Customer
	TrustedModule & receiver in MyStore
}

-- operation MyStore__ListOrder
sig MyStore__ListOrder extends Op {
	MyStore__ListOrder__uid : one UserID,
	MyStore__ListOrder__ret : one OrderID,
}{
	args in MyStore__ListOrder__uid
	ret in MyStore__ListOrder__ret
	TrustedModule & sender in Customer
	TrustedModule & receiver in MyStore
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
	CriticalData = SessionID + Password
}


one sig EvilClient extends Browser {}
one sig EvilServer extends HttpServer {}
one sig EvilHttpReq extends Op {}{
  receiver in EvilServer
}

fact GenericFacts {
  all s : HttpServer, o : receiver.s | o in HTTPReq 
}
run SanityCheck {
  some MyStore__Login & SuccessOp
  some MyStore__PlaceOrder & SuccessOp
  some MyStore__ListOrder & SuccessOp
} for 2 but 4 Data, 5 Op, 5 Step, 4 Module


check Confidentiality {
  Confidentiality
} for 2 but 4 Data, 5 Op, 5 Step, 4 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 4 Data, 5 Op, 5 Step, 4 Module
