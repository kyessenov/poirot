open libraryWeb/WebBasic
open libraryWeb/Redirect

-- module MyStore
one sig MyStore extends HttpServer {
	MyStore__passwords : UserID set -> lone Password,
	MyStore__sessions : UserID set -> lone SessionID,
	MyStore__price : OrderID set -> lone Amount,
	MyStore__orders : (UserID set -> lone OrderID) -> set Op,
	MyStore__paid : (UserID set -> lone OrderID) -> set Op,
}{
	all o : this.receives[MyStore__Login] | (o.MyStore__Login__pwd = MyStore__passwords[o.MyStore__Login__uid] and o.MyStore__Login__ret = MyStore__sessions[o.MyStore__Login__uid])
	all o : this.receives[MyStore__PlaceOrder] | MyStore__orders.(o.next) = (MyStore__orders.o + o.MyStore__PlaceOrder__uid -> o.MyStore__PlaceOrder__oid)
	all o : Op - last | let o' = o.next | MyStore__orders.o' != MyStore__orders.o implies o in MyStore__PlaceOrder & SuccessOp
	this.initAccess in NonCriticalData + UserID.MyStore__passwords + MyStore__passwords.Password + UserID.MyStore__sessions + MyStore__sessions.SessionID + OrderID.MyStore__price + MyStore__price.Amount + UserID.(MyStore__orders.first) + (MyStore__orders.first).OrderID + UserID.(MyStore__paid.first) + (MyStore__paid.first).OrderID
}

-- module PaymentService
one sig PaymentService extends HttpServer {
	PaymentService__transactions : (TxID set -> lone TxInfo) -> set Op,
}{
	all o : this.sends[MyStore__NotifyPayment] | triggeredBy[o,PaymentService__MakePayment]
	all o : this.sends[MyStore__NotifyPayment] | o.MyStore__NotifyPayment__oid = o.trigger.((PaymentService__MakePayment <: PaymentService__MakePayment__oid))
	all o : this.sends[MyStore__NotifyPayment] | o.MyStore__NotifyPayment__amt = o.trigger.((PaymentService__MakePayment <: PaymentService__MakePayment__amt))
	this.initAccess in NonCriticalData + TxID.(PaymentService__transactions.first) + (PaymentService__transactions.first).TxInfo
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
	MyStore__Login__pwd : one Password,
	MyStore__Login__ret : one SessionID,
}{
	args in MyStore__Login__uid + MyStore__Login__pwd
	ret in MyStore__Login__ret
	sender in Customer
	receiver in MyStore
}

-- operation MyStore__PlaceOrder
sig MyStore__PlaceOrder extends Op {
	MyStore__PlaceOrder__uid : one UserID,
	MyStore__PlaceOrder__oid : one OrderID,
}{
	args in MyStore__PlaceOrder__uid + MyStore__PlaceOrder__oid
	no ret
	sender in Customer
	receiver in MyStore
}

-- operation MyStore__Checkout
sig MyStore__Checkout extends Op {
	MyStore__Checkout__sid : one SessionID,
}{
	args in MyStore__Checkout__sid
	no ret
	sender in Customer
	receiver in MyStore
}

-- operation MyStore__NotifyPayment
sig MyStore__NotifyPayment extends Op {
	MyStore__NotifyPayment__oid : one OrderID,
	MyStore__NotifyPayment__amt : one Amount,
}{
	args in MyStore__NotifyPayment__oid + MyStore__NotifyPayment__amt
	no ret
	sender in PaymentService
	receiver in MyStore
}

-- operation PaymentService__MakePayment
sig PaymentService__MakePayment extends Op {
	PaymentService__MakePayment__oid : one OrderID,
	PaymentService__MakePayment__amt : one Amount,
}{
	args in PaymentService__MakePayment__oid + PaymentService__MakePayment__amt
	no ret
	sender in Customer
	receiver in PaymentService
}

-- datatype declarations
sig Token extends Data {
}
sig Resource extends Data {
}
sig UserID extends Data {
}
sig SessionID extends Data {
}
sig Password extends Data {
}
sig Amount extends Data {
}
sig TxID extends Data {
}
sig TxInfo extends Data {
	TxInfo__order : one OrderID,
	TxInfo__amt : one Amount,
}
sig OrderID extends Data {
}
sig OtherData extends Data {}

run SanityCheck {
  some MyStore__Login & SuccessOp
  some MyStore__PlaceOrder & SuccessOp
  some MyStore__Checkout & SuccessOp
  some MyStore__NotifyPayment & SuccessOp
  some PaymentService__MakePayment & SuccessOp
} for 2 but 9 Data, 5 Op, 5 Step, 3 Module


check Confidentiality {
  Confidentiality
} for 2 but 9 Data, 5 Op, 5 Step, 3 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 9 Data, 5 Op, 5 Step, 3 Module
