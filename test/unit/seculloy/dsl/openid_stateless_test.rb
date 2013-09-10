require 'test_helper'
require 'seculloy/case_studies/openid_stateless'

class OpenIdStatelessTest < Test::Unit::TestCase
  include SDGUtils::Testing::SmartSetup
  include SDGUtils::Testing::Assertions
  include OpenID_Stateless

  def view() OpenID_Stateless.meta end

  def test1
    assert OpenID_Stateless
    assert view
  end

  def test_data
    assert_set_equal [Payload, Credential, OpenId, OtherPayload, Addr, URI], view.data
    assert_set_equal [Payload], view.data.select(&:abstract?)
    assert_set_equal [OpenId], view.critical
  end

  def test_mod
    mods = [EndUser, UserAgent, RelyingParty, IdentityProvider]
    assert_set_equal mods, view.modules
    assert_set_equal mods, view.modules.select(&:trusted?)
    assert_set_equal [], view.modules.select(&:many?)
  end

  def test_to_sdsl
    ans = view.to_sdsl
    puts ans.to_alloy
  end

end
