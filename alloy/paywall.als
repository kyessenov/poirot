open models/basic
open models/crypto[Data]

-- module NYTimes
one sig NYTimes extends Module {
	NYTimes__articles : ArticleID set -> lone Article,
}{
	all o : this.receives[NYTimes__GetArticle] | (some (BelowLimit & arg[o.(NYTimes__GetArticle <: NYTimes__GetArticle__numAccessed)]))
	all o : this.sends[Browser__SendArticle] | triggeredBy[o,NYTimes__GetArticle]
	all o : this.sends[Browser__SendArticle] | o.(Browser__SendArticle <: Browser__SendArticle__article) = NYTimes__articles[o.trigger.((NYTimes__GetArticle <: NYTimes__GetArticle__articleID))]
}

-- module Browser
one sig Browser extends Module {
	Browser__numAccessed : lone Number,
}{
	all o : this.sends[Reader__Display] | triggeredBy[o,Browser__SendArticle]
	all o : this.sends[Reader__Display] | o.(Reader__Display <: Reader__Display__article) = o.trigger.((Browser__SendArticle <: Browser__SendArticle__article))
	all o : this.sends[NYTimes__GetArticle] | triggeredBy[o,Browser__SelectArticle]
	all o : this.sends[NYTimes__GetArticle] | o.(NYTimes__GetArticle <: NYTimes__GetArticle__articleID) = o.trigger.((Browser__SelectArticle <: Browser__SelectArticle__articleID))
	all o : this.sends[NYTimes__GetArticle] | o.(NYTimes__GetArticle <: NYTimes__GetArticle__numAccessed) = Browser__numAccessed
}

-- module Reader
one sig Reader extends Module {
}

-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = NYTimes + Browser
}

-- operation NYTimes__GetArticle
sig NYTimes__GetArticle extends Op {
	NYTimes__GetArticle__articleID : lone ArticleID,
	NYTimes__GetArticle__numAccessed : lone Number,
}{
	args = NYTimes__GetArticle__articleID + NYTimes__GetArticle__numAccessed
	sender in Browser
	receiver in NYTimes
}

-- operation Browser__SendArticle
sig Browser__SendArticle extends Op {
	Browser__SendArticle__article : lone Article,
}{
	args = Browser__SendArticle__article
	sender in NYTimes
	receiver in Browser
}

-- operation Browser__SelectArticle
sig Browser__SelectArticle extends Op {
	Browser__SelectArticle__articleID : lone ArticleID,
}{
	args = Browser__SelectArticle__articleID
	sender in Reader
	receiver in Browser
}

-- operation Reader__Display
sig Reader__Display extends Op {
	Reader__Display__article : lone Article,
}{
	args = Reader__Display__article
	sender in Browser
	receiver in Reader
}

-- fact dataFacts
fact dataFacts {
	creates.Article in NYTimes
}

-- datatype declarations
sig Article extends Data {
}{
	no fields
}
sig ArticleID extends Data {
}{
	no fields
}
abstract sig Number extends Data {
}{
}
sig BelowLimit extends Number {
}{
	no fields
}
sig AboveLimit extends Number {
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
