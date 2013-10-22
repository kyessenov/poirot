open models/basic
open models/crypto[Data]

-- module NYTimes
one sig NYTimes extends Module {
	NYTimes__articles : Link set -> lone Article,
	NYTimes__limit : lone Int,
}{
	all o : this.receives[NYTimes__GetLink] | arg[o.(NYTimes__GetLink <: NYTimes__GetLink__numAccessed)] < NYTimes__limit
	all o : this.sends[Client__SendPage] | triggeredBy[o,NYTimes__GetLink]
	all o : this.sends[Client__SendPage] | o.(Client__SendPage <: Client__SendPage__page) = NYTimes__articles[o.trigger.((NYTimes__GetLink <: NYTimes__GetLink__link))]
	all o : this.sends[Client__SendPage] | o.(Client__SendPage <: Client__SendPage__newCounter) = (o.trigger.((NYTimes__GetLink <: NYTimes__GetLink__numAccessed)) + 1)
}

-- module Client
one sig Client extends Module {
	Client__numAccessed : Int lone -> set Step,
}{
	all o : this.receives[Client__SendPage] | Client__numAccessed.(o.post) = arg[o.(Client__SendPage <: Client__SendPage__newCounter)] and arg[o.(Client__SendPage <: Client__SendPage__newCounter)]
	all o : this.sends[Reader__DisplayPage] | triggeredBy[o,Client__SendPage]
	all o : this.sends[Reader__DisplayPage] | o.(Reader__DisplayPage <: Reader__DisplayPage__page) = o.trigger.((Client__SendPage <: Client__SendPage__page))
	all o : this.sends[NYTimes__GetLink] | triggeredBy[o,Client__SelectLink]
	all o : this.sends[NYTimes__GetLink] | o.(NYTimes__GetLink <: NYTimes__GetLink__link) = o.trigger.((Client__SelectLink <: Client__SelectLink__link))
	all o : this.sends[NYTimes__GetLink] | o.(NYTimes__GetLink <: NYTimes__GetLink__numAccessed) = Client__numAccessed.(o.pre)
}

-- module Reader
one sig Reader extends Module {
}

-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = NYTimes + Client
}

-- operation NYTimes__GetLink
sig NYTimes__GetLink extends Op {
	NYTimes__GetLink__link : lone Link,
	NYTimes__GetLink__numAccessed : lone Int,
}{
	args = NYTimes__GetLink__link + NYTimes__GetLink__numAccessed
	no ret
	sender in Client
	receiver in NYTimes
}

-- operation Client__SendPage
sig Client__SendPage extends Op {
	Client__SendPage__page : lone Page,
	Client__SendPage__newCounter : lone Int,
}{
	args = Client__SendPage__page + Client__SendPage__newCounter
	no ret
	sender in NYTimes
	receiver in Client
}

-- operation Client__SelectLink
sig Client__SelectLink extends Op {
	Client__SelectLink__link : lone Link,
}{
	args = Client__SelectLink__link
	no ret
	sender in Reader
	receiver in Client
}

-- operation Reader__DisplayPage
sig Reader__DisplayPage extends Op {
	Reader__DisplayPage__page : lone Page,
}{
	args = Reader__DisplayPage__page
	no ret
	sender in Client
	receiver in Reader
}

-- fact dataFacts
fact dataFacts {
	creates.Article in NYTimes
}

-- datatype declarations
abstract sig Page extends Data {
}{
}
sig Article extends Page {
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
	CriticalData = Article
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
