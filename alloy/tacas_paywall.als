open models/basic
open models/crypto[Data]

-- module NYTimes
one sig NYTimes extends Module {
	NYTimes__articles : Link set -> lone Page,
	NYTimes__limit : lone Int,
}{
	all o : this.receives[NYTimes__GetPage] | arg[o.(NYTimes__GetPage <: NYTimes__GetPage__currCounter)] < NYTimes__limit
	all o : this.sends[Client__SendPage] | triggeredBy[o,NYTimes__GetPage]
	all o : this.sends[Client__SendPage] | o.(Client__SendPage <: Client__SendPage__page) = NYTimes__articles[o.trigger.((NYTimes__GetPage <: NYTimes__GetPage__link))]
	all o : this.sends[Client__SendPage] | o.(Client__SendPage <: Client__SendPage__newCounter) = plus[o.trigger.((NYTimes__GetPage <: NYTimes__GetPage__currCounter)), 1]
}

-- module Client
one sig Client extends Module {
	Client__counter : Int lone -> set Step,
}{
	all o : this.receives[Client__SendPage] | Client__counter.(o.post) = arg[o.(Client__SendPage <: Client__SendPage__newCounter)]
	all o : this.sends[Reader__Display] | triggeredBy[o,Client__SendPage]
	all o : this.sends[Reader__Display] | o.(Reader__Display <: Reader__Display__page) = o.trigger.((Client__SendPage <: Client__SendPage__page))
	all o : this.sends[NYTimes__GetPage] | triggeredBy[o,Client__SelectLink]
	all o : this.sends[NYTimes__GetPage] | o.(NYTimes__GetPage <: NYTimes__GetPage__link) = o.trigger.((Client__SelectLink <: Client__SelectLink__link))
	all o : this.sends[NYTimes__GetPage] | o.(NYTimes__GetPage <: NYTimes__GetPage__currCounter) = Client__counter.(o.pre)
}

-- module Reader
one sig Reader extends Module {
}

-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = NYTimes + Client
}

-- operation NYTimes__GetPage
sig NYTimes__GetPage extends Op {
	NYTimes__GetPage__link : lone Link,
	NYTimes__GetPage__currCounter : lone Int,
}{
	args = NYTimes__GetPage__link + NYTimes__GetPage__currCounter
	sender in Client
	receiver in NYTimes
}

-- operation Client__SendPage
sig Client__SendPage extends Op {
	Client__SendPage__page : lone Page,
	Client__SendPage__newCounter : lone Int,
}{
	args = Client__SendPage__page + Client__SendPage__newCounter
	sender in NYTimes
	receiver in Client
}

-- operation Client__SelectLink
sig Client__SelectLink extends Op {
	Client__SelectLink__link : lone Link,
}{
	args = Client__SelectLink__link
	sender in Reader
	receiver in Client
}

-- operation Reader__Display
sig Reader__Display extends Op {
	Reader__Display__page : lone Page,
}{
	args = Reader__Display__page
	sender in Client
	receiver in Reader
}

-- fact dataFacts
fact dataFacts {
	creates.Page in NYTimes
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


fun RelevantOp : Op -> Step {
	{o : Op, t : Step | o.post = t and o in SuccessOp}
}

run SanityCheck {
	all m : Module |
		some sender.m & SuccessOp
} for 1 but 9 Data, 10 Step, 9 Op

check Confidentiality {
   Confidentiality
} for 1 but 9 Data, 10 Step, 9 Op

-- check who can create CriticalData
check Integrity {
   Integrity
} for 1 but 9 Data, 10 Step, 9 Op
