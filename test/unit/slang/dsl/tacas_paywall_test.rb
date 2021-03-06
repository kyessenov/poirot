require 'test_helper'

require 'slang/model/refinement'

require 'slang/case_studies/tacas_paywall'

require 'sdsl/myutils'


class TacasPaywallTest < Test::Unit::TestCase
  include SDGUtils::Testing::SmartSetup
  include SDGUtils::Testing::Assertions

  include Slang::Model

  include TacasPaywall

Expected_alloy = """
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
	args = NYTimes__GetPage__link + NYTimes__GetPage__currCounter
	no ret
	sender in Client
	receiver in NYTimes
}

-- operation Client__SendPage
sig Client__SendPage extends Op {
	Client__SendPage__page : one Page,
	Client__SendPage__newCounter : one Int,
}{
	args = Client__SendPage__page + Client__SendPage__newCounter
	no ret
	sender in NYTimes
	receiver in Client
}

-- operation Client__SelectLink
sig Client__SelectLink extends Op {
	Client__SelectLink__link : one Link,
}{
	args = Client__SelectLink__link
	no ret
	sender in Reader
	receiver in Client
}

-- operation Reader__Display
sig Reader__Display extends Op {
	Reader__Display__page : one Page,
}{
	args = Reader__Display__page
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
"""

  def view() TacasPaywall.meta end

  def test1
    assert view
  end

  def test2
    ans = view.to_sdsl
    assert ans
    dumpAlloy(ans, "alloy/tacas_paywall.als")
    puts ans.to_alloy
    assert_equal Expected_arby.strip, ans.to_arby.strip
  end

end
