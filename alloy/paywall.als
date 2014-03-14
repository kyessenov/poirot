open models/basicNoStep

-- module NYTimes
one sig NYTimes extends Module {
	NYTimes__articles : Link set -> lone Article,
	NYTimes__limit : one Int,
}{
	all o : this.receives[NYTimes__GetLink] | o.(NYTimes__GetLink <: NYTimes__GetLink__numAccessed) < NYTimes__limit
	all o : this.sends[Client__SendPage] | triggeredBy[o,NYTimes__GetLink]
	all o : this.sends[Client__SendPage] | o.(Client__SendPage <: Client__SendPage__page) = NYTimes__articles[o.trigger.((NYTimes__GetLink <: NYTimes__GetLink__link))]
	all o : this.sends[Client__SendPage] | o.(Client__SendPage <: Client__SendPage__newCounter) = plus[o.trigger.((NYTimes__GetLink <: NYTimes__GetLink__numAccessed)), 1]
	this.initAccess in NonCriticalData + Link.NYTimes__articles + NYTimes__articles.Article + NYTimes__limit + Article
}

-- module Client
one sig Client extends Module {
	Client__numAccessed : Int one -> set Step,
}{
	all o : this.receives[Client__SendPage] | Client__numAccessed.(o.post) = o.(Client__SendPage <: Client__SendPage__newCounter)
	all o : this.sends[Reader__DisplayPage] | triggeredBy[o,Client__SendPage]
	all o : this.sends[Reader__DisplayPage] | o.(Reader__DisplayPage <: Reader__DisplayPage__page) = o.trigger.((Client__SendPage <: Client__SendPage__page))
	all o : this.sends[NYTimes__GetLink] | triggeredBy[o,Client__SelectLink]
	all o : this.sends[NYTimes__GetLink] | o.(NYTimes__GetLink <: NYTimes__GetLink__link) = o.trigger.((Client__SelectLink <: Client__SelectLink__link))
	all o : this.sends[NYTimes__GetLink] | o.(NYTimes__GetLink <: NYTimes__GetLink__numAccessed) = NYTimes__GetLink__numAccessed
	all t : Step - last | let t' = t.next | Client__numAccessed.t' != Client__numAccessed.t implies some ((Client__SendPage) & SuccessOp) & pre.t
	this.initAccess in NonCriticalData + (Client__numAccessed.first)
}

-- module Reader
one sig Reader extends Module {
}{
	this.initAccess in NonCriticalData
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = NYTimes + Client
}

-- operation NYTimes__GetLink
sig NYTimes__GetLink extends Op {
	NYTimes__GetLink__link : one Link,
	NYTimes__GetLink__numAccessed : one Int,
}{
	args in NYTimes__GetLink__link + NYTimes__GetLink__numAccessed
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

-- operation Reader__DisplayPage
sig Reader__DisplayPage extends Op {
	Reader__DisplayPage__page : one Page,
}{
	args in Reader__DisplayPage__page
	no ret
	sender in Client
	receiver in Reader
}

-- datatype declarations
abstract sig Page extends Data {
}{
	no fields
}
sig Article extends Data {
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

run SanityCheck {
  some NYTimes__GetLink & SuccessOp
  some Client__SendPage & SuccessOp
  some Client__SelectLink & SuccessOp
  some Reader__DisplayPage & SuccessOp
} for 2 but 3 Data, 4 Op, 3 Module


check Confidentiality {
  Confidentiality
} for 2 but 3 Data, 4 Op, 3 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 3 Data, 4 Op, 3 Module
