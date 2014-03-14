open models/basicNoStep

-- module FrontDesk
one sig FrontDesk extends Module {
	FrontDesk__lastKey : (RoomNumber set -> lone Key) -> set Step,
	FrontDesk__occupant : (RoomNumber set -> lone GuestID) -> set Step,
}{
	all o : this.receives[FrontDesk__Checkin] | o.(FrontDesk__Checkin <: FrontDesk__Checkin__ret) = FrontDesk__lastKey.(o.pre)[o.(FrontDesk__Checkin <: FrontDesk__Checkin__rm)].Key__nxt
	all o : this.receives[FrontDesk__Checkin] | o.(FrontDesk__Checkin <: FrontDesk__Checkin__guest).Guest__keys = (o.(FrontDesk__Checkin <: FrontDesk__Checkin__guest).Guest__keys + o.(FrontDesk__Checkin <: FrontDesk__Checkin__ret)) and FrontDesk__lastKey.(o.post) = (FrontDesk__lastKey.(o.pre) + o.(FrontDesk__Checkin <: FrontDesk__Checkin__rm) -> o.(FrontDesk__Checkin <: FrontDesk__Checkin__ret)) and FrontDesk__occupant.(o.post) = (FrontDesk__occupant.(o.pre) + o.(FrontDesk__Checkin <: FrontDesk__Checkin__rm) -> o.(FrontDesk__Checkin <: FrontDesk__Checkin__guest).Guest__id)
	all o : this.receives[FrontDesk__Checkout] | (some FrontDesk__occupant.(o.pre).id)
	all o : this.receives[FrontDesk__Checkout] | (not (some FrontDesk__occupant.(o.pre).id))
	all t : Step - last | let t' = t.next | FrontDesk__lastKey.t' != FrontDesk__lastKey.t implies some ((FrontDesk__Checkin) & SuccessOp) & pre.t
	all t : Step - last | let t' = t.next | FrontDesk__occupant.t' != FrontDesk__occupant.t implies some ((FrontDesk__Checkin) & SuccessOp) & pre.t
	this.initAccess in NonCriticalData + RoomNumber.(FrontDesk__lastKey.first) + (FrontDesk__lastKey.first).Key + RoomNumber.(FrontDesk__occupant.first) + (FrontDesk__occupant.first).GuestID + Key
}

-- module Room
one sig Room extends Module {
	Room__num : one RoomNumber,
	Room__keys : set Key,
	Room__currentKey : Key one -> set Step,
}{
	all o : this.receives[Room__Entry] | 
		(o.(Room__Entry <: Room__Entry__k) = Room__currentKey.(o.pre)
		or
		o.(Room__Entry <: Room__Entry__k) = Room__currentKey.(o.pre).Key__nxt
		)
	all o : this.receives[Room__Entry] | Room__currentKey.(o.post) = Room__currentKey.(o.pre).Key__nxt
	(some (Room__keys & Room__currentKey.(o.pre)))
	all t : Step - last | let t' = t.next | Room__currentKey.t' != Room__currentKey.t implies some ((Room__Entry) & SuccessOp) & pre.t
	this.initAccess in NonCriticalData + Room__num + Room__keys + (Room__currentKey.first)
}

-- module Guest
one sig Guest extends Module {
	Guest__id : one GuestID,
	Guest__keys : set Key,
}{
	this.initAccess in NonCriticalData + Guest__id + Guest__keys
}

-- module GoodGuest
one sig GoodGuest extends Guest {
}{
	this.initAccess in NonCriticalData
}

-- module BadGuest
one sig BadGuest extends Guest {
}{
	this.initAccess in NonCriticalData
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = FrontDesk + Room + GoodGuest
}

-- operation FrontDesk__Checkin
sig FrontDesk__Checkin extends Op {
	FrontDesk__Checkin__guest : one Guest,
	FrontDesk__Checkin__rm : one RoomNumber,
	FrontDesk__Checkin__ret : one Key,
}{
	args in FrontDesk__Checkin__guest + FrontDesk__Checkin__rm
	ret in FrontDesk__Checkin__ret
	sender in Guest
	receiver in FrontDesk
}

-- operation FrontDesk__Checkout
sig FrontDesk__Checkout extends Op {
	FrontDesk__Checkout__id : one GuestID,
}{
	args in FrontDesk__Checkout__id
	no ret
	sender in Guest
	receiver in FrontDesk
}

-- operation Room__Entry
sig Room__Entry extends Op {
	Room__Entry__k : one Key,
}{
	args in Room__Entry__k
	no ret
	sender in Guest
	receiver in Room
}

-- datatype declarations
sig Key extends Data {
	Key__nxt : one Int,
}{
	fields in Key__nxt
}
sig RoomNumber extends Data {
}{
	no fields
}
sig GuestID extends Data {
}{
	no fields
}
sig OtherData extends Data {}{ no fields }

run SanityCheck {
  some FrontDesk__Checkin & SuccessOp
  some FrontDesk__Checkout & SuccessOp
  some Room__Entry & SuccessOp
} for 2 but 3 Data, 3 Op, 5 Module


check Confidentiality {
  Confidentiality
} for 2 but 3 Data, 3 Op, 5 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 3 Data, 3 Op, 5 Module
