open libraryWeb/WebBasic
open libraryWeb/Redirect

-- module MyStore
one sig MyStore extends HttpServer {
	MyStore__passwords : UserID set -> lone Password,
	MyStore__sessions : UserID set -> lone SessionID,
	MyStore__price : OrderID set -> lone Amount,
	MyStore__orders : (UserID set -> lone OrderID) -> set Op,
	MyStore__paid : OrderID set -> set Op,
}{
	all o : this.receives[MyStore__Login] | ((o.MyStore__Login__pwd) = MyStore__passwords[(o.MyStore__Login__uid)] and (o.MyStore__Login__ret) = MyStore__sessions[(o.MyStore__Login__uid)])
	all o : this.receives[MyStore__PlaceOrder] | MyStore__orders.(o.next) = (MyStore__orders.o + ((o.MyStore__PlaceOrder__uid) -> (o.MyStore__PlaceOrder__oid)))
	all o : this.receives[MyStore__Checkout] | (((o.MyStore__Checkout__ret).PaymentInfo__order) = MyStore__orders.o[(MyStore__sessions.(o.MyStore__Checkout__sid))] and ((o.MyStore__Checkout__ret).PaymentInfo__amtCharged) = MyStore__price[((o.MyStore__Checkout__ret).PaymentInfo__order)])
	all o : this.receives[MyStore__NotifyPayment] | MyStore__paid.(o.next) = (MyStore__paid.o + (o.MyStore__NotifyPayment__oid))
	all o : Op - last | let o' = o.next | MyStore__orders.o' != MyStore__orders.o implies o in MyStore__PlaceOrder & SuccessOp
	all o : Op - last | let o' = o.next | MyStore__paid.o' != MyStore__paid.o implies o in MyStore__NotifyPayment & SuccessOp
	this.initAccess in this.MyStoreInitData
}
fun MyStoreInitData[m : Module] : set Data {
	NonCriticalData + UserID.(m.MyStore__passwords) + (m.MyStore__passwords).Password + UserID.(m.MyStore__sessions) + (m.MyStore__sessions).SessionID + OrderID.(m.MyStore__price) + (m.MyStore__price).Amount + UserID.((m.MyStore__orders).first) + ((m.MyStore__orders).first).OrderID + ((m.MyStore__paid).first)
}

-- module PaymentService
one sig PaymentService extends HttpServer {
	PaymentService__transactions : (TxID set -> lone TxInfo) -> set Op,
}{
	all o : this.receives[PaymentService__MakePayment] | (some t : TxID | (some i : TxInfo | (((i.TxInfo__order) = (o.PaymentService__MakePayment__oid) and (i.TxInfo__amtPaid) = (o.PaymentService__MakePayment__amt)) and PaymentService__transactions.(o.next) = (PaymentService__transactions.o + (t -> i)))))
	all o : this.sends[MyStore__NotifyPayment] | triggeredBy[o,PaymentService__MakePayment]
	all o : this.sends[MyStore__NotifyPayment] | (o.MyStore__NotifyPayment__oid) = ((o.trigger).PaymentService__MakePayment__oid)
	all o : Op - last | let o' = o.next | PaymentService__transactions.o' != PaymentService__transactions.o implies o in PaymentService__MakePayment & SuccessOp
	this.initAccess in this.PaymentServiceInitData
}
fun PaymentServiceInitData[m : Module] : set Data {
	NonCriticalData + TxID.((m.PaymentService__transactions).first) + ((m.PaymentService__transactions).first).TxInfo
}

-- module Customer
one sig Customer extends Browser {
	Customer__myId : one UserID,
	Customer__myPwd : one Password,
}{
	all o : this.sends[PaymentService__MakePayment] | triggeredBy[o,MyStore__PlaceOrder]
	this.initAccess in this.CustomerInitData
}
fun CustomerInitData[m : Module] : set Data {
	NonCriticalData + (m.Customer__myId) + (m.Customer__myPwd)
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

-- operation MyStore__Checkout
sig MyStore__Checkout extends Op {
	MyStore__Checkout__sid : one SessionID,
	MyStore__Checkout__ret : one PaymentInfo,
}{
	args in MyStore__Checkout__sid
	ret in MyStore__Checkout__ret
	TrustedModule & sender in Customer
	TrustedModule & receiver in MyStore
}

-- operation MyStore__NotifyPayment
sig MyStore__NotifyPayment extends Op {
	MyStore__NotifyPayment__oid : one OrderID,
}{
	args in MyStore__NotifyPayment__oid
	no ret
	TrustedModule & sender in PaymentService
	TrustedModule & receiver in MyStore
}

-- operation PaymentService__MakePayment
sig PaymentService__MakePayment extends Op {
	PaymentService__MakePayment__oid : one OrderID,
	PaymentService__MakePayment__amt : one Amount,
}{
	args in PaymentService__MakePayment__oid + PaymentService__MakePayment__amt
	no ret
	TrustedModule & sender in Customer
	TrustedModule & receiver in PaymentService
}

-- datatype declarations
sig UserID extends Data {
}
sig SessionID extends Data {
}
sig Password extends Data {
}
sig Amount extends Data {
}
sig OrderID extends Data {
}
sig PaymentInfo extends Data {
	PaymentInfo__order : one OrderID,
	PaymentInfo__amtCharged : one Amount,
}
sig TxID extends Data {
}
sig TxInfo extends Data {
	TxInfo__order : one OrderID,
	TxInfo__amtPaid : one Amount,
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
  some MyStore__Checkout & SuccessOp
  some MyStore__NotifyPayment & SuccessOp
  some PaymentService__MakePayment & SuccessOp
} for 2 but 8 Data, 7 Op, 7 Step, 5 Module


check Confidentiality {
  Confidentiality
} for 2 but 8 Data, 7 Op, 7 Step, 5 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 8 Data, 7 Op, 7 Step, 5 Module

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
