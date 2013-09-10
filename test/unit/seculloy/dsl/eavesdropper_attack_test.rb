require 'test_helper'
require 'seculloy/case_studies/attacks/eavesdropper'

class ReplayAttackTest < Test::Unit::TestCase
  include SDGUtils::Testing::SmartSetup
  include SDGUtils::Testing::Assertions
  include EavesdropperAttack

  def view() EavesdropperAttack.meta end

  def test1
    assert EavesdropperAttack
    assert view
  end

  def test_data
    assert_set_equal [Packet], view.data
    assert_set_equal [], view.data.select(&:abstract?)
  end

  def test_mod
    mods = [EndpointA, EndpointB, Channel, Eavesdropper]
    assert_set_equal mods, view.modules
    assert_set_equal mods, view.modules.select(&:trusted?)
    assert_set_equal [], view.modules.select(&:many?)
  end


  def test_to_sdsl
    ans = view.to_sdsl
    puts ans.to_alloy
  end

end
