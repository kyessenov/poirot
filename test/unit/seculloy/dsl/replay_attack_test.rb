require 'test_helper'
require 'seculloy/case_studies/attacks/replay'

class ReplayAttackTest < Test::Unit::TestCase
  include SDGUtils::Testing::SmartSetup
  include SDGUtils::Testing::Assertions
  include ReplayAttack

  def view() ReplayAttack.meta end

  def test1
    assert ReplayAttack
    assert view
  end

  def test_data
    assert_set_equal [Packet], view.data
    assert_set_equal [], view.data.select(&:abstract?)
  end

  def test_mod
    assert_set_equal [EndPoint, Channel, Eavesdropper], view.modules
    assert_set_equal [EndPoint, Channel, Eavesdropper], view.modules.select(&:trusted?)
    assert_set_equal [EndPoint], view.modules.select(&:many?)
  end

  def test_to_sdsl
    ans = view.to_sdsl
    puts ans.to_alloy
  end

end
