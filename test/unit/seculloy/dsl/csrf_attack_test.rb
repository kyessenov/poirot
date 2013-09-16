require 'test_helper'
require 'seculloy/case_studies/attacks/csrf'
require 'seculloy/utils/sdsl_converter'

class CSRFAttackTest < Test::Unit::TestCase
  include SDGUtils::Testing::SmartSetup
  include SDGUtils::Testing::Assertions
  include CSRF

  def view() CSRF.meta end

  def test1
    assert CSRF
    assert view
  end

  def test_data
    assert_set_equal [Payload, Cookie, OtherPayload, Addr,
                      URI, HtmlTag, ImgTag, DOM, Hostname], view.data
    assert_set_equal [Payload, HtmlTag], view.data.select(&:abstract?)
  end

  def test_mod
    assert_set_equal [User, Client, TrustedServer, MaliciousServer], view.modules
    assert_set_equal [User, Client, TrustedServer], view.modules.select(&:trusted?)
    assert_set_equal [], view.modules.select(&:many?)
  end

  def test_trusted_server
    assert_set_equal %w(cookies addr protectedOps), TrustedServer.meta.fields.map(&:name)
    assert_seq_equal [Seculloy::Model::Operation, Cookie],
                     TrustedServer.meta.field(:cookies).type.to_ruby_type
    assert_seq_equal [Seculloy::Model::Operation],
                     TrustedServer.meta.field(:protectedOps).type.to_ruby_type
  end

  def test_ts_http_req
    op = TrustedServer::HttpReq.meta
    assert_equal 1, op.guards.size
    assert op.guards.first.sym_exe
  end

  def test_to_sdsl
    ans = view.to_sdsl
    puts ans.to_alloy
  end

end
