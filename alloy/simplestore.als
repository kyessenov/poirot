open libraryWeb/WebBasic
open libraryWeb/Redirect

-- module MyStore
one sig MyStore extends HttpServer {
	MyStore__passwords : UserID set -> lone Password,
	MyStore__products : ProductID set -> lone ProductInfo,
	MyStore__orders : (UserID set -> lone ProductID) -> set Op,
}{
	all o : this.receives[MyStore__Login] | (o.MyStore__Login__pass) = MyStore__passwords[(o.MyStore__Login__uid)]
	all o : this.receives[MyStore__GetProduct] | (o.MyStore__GetProduct__ret) = MyStore__products[(o.MyStore__GetProduct__pid)]
	all o : this.receives[MyStore__OrderProduct] | MyStore__orders.(o.next) = (MyStore__orders.o + ((o.MyStore__OrderProduct__uid) -> (o.MyStore__OrderProduct__pid)))
	all o : Op - last | let o' = o.next | MyStore__orders.o' != MyStore__orders.o implies o in MyStore__OrderProduct & SuccessOp
	this.initAccess in NonCriticalData + UserID.MyStore__passwords + MyStore__passwords.Password + ProductID.MyStore__products + MyStore__products.ProductInfo + UserID.(MyStore__orders.first) + (MyStore__orders.first).ProductID
}

-- module Customer
one sig Customer extends Browser {
	Customer__id : one UserID,
	Customer__pass : one Password,
}{
	this.initAccess in NonCriticalData + Customer__id + Customer__pass
}


-- operation MyStore__Login
sig MyStore__Login extends Op {
	MyStore__Login__uid : one UserID,
	MyStore__Login__pass : one Password,
}{
	args in MyStore__Login__uid + MyStore__Login__pass
	no ret
	sender in Customer
	receiver in MyStore
}

-- operation MyStore__GetProduct
sig MyStore__GetProduct extends Op {
	MyStore__GetProduct__pid : one ProductID,
	MyStore__GetProduct__ret : one ProductInfo,
}{
	args in MyStore__GetProduct__pid
	ret in MyStore__GetProduct__ret
	sender in Customer
	receiver in MyStore
}

-- operation MyStore__OrderProduct
sig MyStore__OrderProduct extends Op {
	MyStore__OrderProduct__uid : one UserID,
	MyStore__OrderProduct__pid : one ProductID,
}{
	args in MyStore__OrderProduct__uid + MyStore__OrderProduct__pid
	no ret
	sender in Customer
	receiver in MyStore
}

-- datatype declarations
sig UserID extends Data {
}
sig ProductID extends Data {
}
sig ProductInfo extends Data {
}
sig Password extends Data {
}
sig OtherData extends Data {}

run SanityCheck {
  some MyStore__Login & SuccessOp
  some MyStore__GetProduct & SuccessOp
  some MyStore__OrderProduct & SuccessOp
} for 2 but 4 Data, 3 Op, 3 Step, 2 Module


check Confidentiality {
  Confidentiality
} for 2 but 4 Data, 3 Op, 3 Step, 2 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 4 Data, 3 Op, 3 Step, 2 Module
