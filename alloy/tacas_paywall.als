open models/basic
open models/crypto[Data]

-- module NYTimes
one sig NYTimes extends Module {
	NYTimes__articles : Link set -> lone Page,
	NYTimes__limit : one Int,
}{
	all o : this.receives[NYTimes__GetPage] | o.(NYTimes__GetPage <: NYTimes__GetPage__currCounter) < NYTimes__limit
	all o : this.sends[Client__SendPage] | triggeredBy[o,NYTimes__GetPage]
	all o : this.sends[Client__SendPage] | o.(Client__SendPage <: Client__SendPage__page) = NYTimes__articles[o.trigger.((NYTimes__GetPage <: NYTimes__GetPage__link))]
	all o : this.sends[Client__SendPage] | o.(Client__SendPage <: Client__SendPage__newCounter) = plus[o.trigger.((NYTimes__GetPage <: NYTimes__GetPage__currCounter)), 1]
	accesses.first in NonCriticalData + Link.NYTimes__articles + NYTimes__articles.Page + NYTimes__limit + Page
}

-- module Client
one sig Client extends Module {
	Client__counter : Int one -> set Step,
}{
	all o : this.receives[Client__SendPage] | Client__counter.(o.post) = o.(Client__SendPage <: Client__SendPage__newCounter)
	all o : this.sends[Reader__Display] | triggeredBy[o,Client__SendPage]
	all o : this.sends[Reader__Display] | o.(Reader__Display <: Reader__Display__page) = o.trigger.((Client__SendPage <: Client__SendPage__page))
	all o : this.sends[NYTimes__GetPage] | triggeredBy[o,Client__SelectLink]
	all o : this.sends[NYTimes__GetPage] | o.(NYTimes__GetPage <: NYTimes__GetPage__link) = o.trigger.((Client__SelectLink <: Client__SelectLink__link))
	all o : this.sends[NYTimes__GetPage] | o.(NYTimes__GetPage <: NYTimes__GetPage__currCounter) = Client__counter.(o.pre)
	all t : Step - last | let t' = t.next | Client__counter.t' != Client__counter.t implies some ((Client__SendPage) & SuccessOp) & pre.t
	accesses.first in NonCriticalData + (Client__counter.first)
}

-- module Reader
one sig Reader extends Module {
}{
	accesses.first in NonCriticalData
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = NYTimes + Client
}

-- operation NYTimes__GetPage
sig NYTimes__GetPage extends Op {
	NYTimes__GetPage__link : one Link,
	NYTimes__GetPage__currCounter : one Int,
}{
	args in NYTimes__GetPage__link + NYTimes__GetPage__currCounter
	no ret
	sender in Client
	receiver in NYTimes
}

-- operation Client__SendPage
sig Client__SendPage extends Op {
	Client__SendPage__page : one Page,
	Client__SendPage__newCounter : one Int,
}{
	args in Client__SendPage__page + Client__SendPage__newCounter
	no ret
	sender in NYTimes
	receiver in Client
}

-- operation Client__SelectLink
sig Client__SelectLink extends Op {
	Client__SelectLink__link : one Link,
}{
	args in Client__SelectLink__link
	no ret
	sender in Reader
	receiver in Client
}

-- operation Reader__Display
sig Reader__Display extends Op {
	Reader__Display__page : one Page,
}{
	args in Reader__Display__page
	no ret
	sender in Client
	receiver in Reader
}

-- datatype declarations
sig Page extends Data {
}{
	no fields
}
sig Link extends Data {
}{
	no fields
}
sig OtherData extends Data {}{ no fields }

-- fact criticalDataFacts
fact criticalDataFacts {
	CriticalData = Page
}

run SanityCheck {
  some NYTimes__GetPage & SuccessOp
  some Client__SendPage & SuccessOp
  some Client__SelectLink & SuccessOp
  some Reader__Display & SuccessOp
} for 1 but 2 Data, 5 Step,4 Op, 3 Module


fun RelevantOp : Op -> Step {
  {o : Op, t : Step | o.post = t and o in SuccessOp}
}
check Confidentiality {
  Confidentiality
} for 1 but 2 Data, 5 Step,4 Op, 3 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 1 but 2 Data, 5 Step,4 Op, 3 Module

