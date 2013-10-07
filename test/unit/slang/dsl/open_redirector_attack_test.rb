require 'test_helper'
require 'slang/case_studies/attacks/open_redirector'
require 'slang/utils/sdsl_converter'

class ReplayAttackTest < Test::Unit::TestCase
  include SDGUtils::Testing::SmartSetup
  include SDGUtils::Testing::Assertions
  include OpenRedirector

  def view() OpenRedirector.meta end

  def test1
    assert OpenRedirector
    assert view
  end

  def test_data
    assert_set_equal [URI], view.data
    assert_set_equal [], view.data.select(&:abstract?)
  end

  def test_mod
    assert_set_equal [User, Client, TrustedServer, MaliciousServer], view.modules
    assert_set_equal [User, Client, TrustedServer], view.modules.select(&:trusted?)
    assert_set_equal [], view.modules.select(&:many?)
  end

  def test_user
    assert_equal 1, User.meta.guards.size
    assert guard_expr=User.meta.guards.first.sym_exe    
    assert Slang::Utils::SdslConverter.new.convert_expr(guard_expr)

    assert_equal 1, User.meta.triggers.size
    assert Slang::Utils::SdslConverter.new.convert_trigger(User.meta.triggers.first)
  end

  def test_to_sdsl
    ans = view.to_sdsl
    puts ans.to_alloy
  end

end
