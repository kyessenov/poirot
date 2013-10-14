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
	NYTimes__articles : Link some -> lone Page,
	NYTimes__limit : lone Int,
}{
	all o : this.receives[NYTimes__GetPage] | arg[o.(NYTimes__GetPage <: NYTimes__GetPage__currCounter)] < NYTimes__limit
	all o : this.sends[Client__SendPage] | triggeredBy[o,NYTimes__GetPage]
	all o : this.sends[Client__SendPage] | o.(Client__SendPage <: Client__SendPage__page) = NYTimes__articles[o.trigger.((NYTimes__GetPage <: NYTimes__GetPage__link))]
}

-- module Client
one sig Client extends Module {
	Client__counter : Int lone -> some Step,
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
    assert_equal Expected_alloy.strip, ans.to_alloy.strip
  end

end
