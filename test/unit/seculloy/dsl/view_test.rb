require 'test_helper'
require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

view :OAuth do
  abstract_data Payload
  data Credential  < Payload
  data AuthGrant   < Payload
  data AccessToken < Payload
  data Resource    < Payload

  mod Client, {
    cred: Credential
  } do
    creates Credential

    operation sendResp[data: Payload]
  end

  mod ResourceOwner, {
    authGrants: Credential * AuthGrant
  } do
    creates AuthGrant

    operation reqAuth[cred: Credential]  do
      guard {
        cred.in? authGrants.keys
      }

      effects(client: Client) {
        client.sendResp(authGrants[cred])
      }
    end
  end

  mod AuthServer, {
    accessTokens: AuthGrant * AccessToken
  } do
    creates AccessToken

    operation reqAccessToken[authGrant: AuthGrant]  do
      guard {
        authGrant.in? accessTokens.keys
      }

      effects(client: Client) {
        client.sendResp(accessTokens[authGrant])
      }
    end
  end

  mod ResourceServer, {
    resources: AccessToken * Resource
  } do
    creates Resource

    operation reqResource[accessToken: AccessToken]  do
      guard {
        accessToken.in? resources.keys
      }

      effects(client: Client) {
        client.sendResp(resources[accessToken])
      }
    end
  end

end

class ViewTest < Test::Unit::TestCase
  include SDGUtils::Testing::SmartSetup
  include SDGUtils::Testing::Assertions
  include OAuth

  def oauth() OAuth.meta end

  def test1
    assert OAuth
    oauth = OAuth.meta
    assert oauth
  end

  def test_data
    assert_set_equal [Payload, Credential, AuthGrant, AccessToken, Resource], oauth.data
  end

  def test_mod
    assert_set_equal [ResourceOwner, Client, AuthServer, ResourceServer], oauth.modules
  end

  def test_fields
    assert_seq_equal ["cred"],         Client.meta.fields.map(&:name)
    assert_seq_equal ["authGrants"],   ResourceOwner.meta.fields.map(&:name)
    assert_seq_equal ["accessTokens"], AuthServer.meta.fields.map(&:name)
    assert_seq_equal ["resources"],    ResourceServer.meta.fields.map(&:name)
  end

  def test_creates
    assert_seq_equal [Credential],  Client.meta.creates
    assert_seq_equal [AuthGrant],   ResourceOwner.meta.creates
    assert_seq_equal [AccessToken], AuthServer.meta.creates
    assert_seq_equal [Resource],    ResourceServer.meta.creates
  end

  def test_exports
    assert_seq_equal ["sendResp"],       Client.meta.operations.map(&:name)
    assert_seq_equal ["reqAuth"],        ResourceOwner.meta.operations.map(&:name)
    assert_seq_equal ["reqAccessToken"], AuthServer.meta.operations.map(&:name)
    assert_seq_equal ["reqResource"],    ResourceServer.meta.operations.map(&:name)
  end

  def do_test_op(op, fields, guards, effects)
    assert_equal fields.size, op.meta.fields.size
    fields.each do |name, cls|
      assert fld=op.meta.field(name)
      assert_equal cls,  fld.type.klass
    end

    assert_equal guards.size, op.meta.guards.size
    op.meta.guards.each_with_index do |guard, idx|
      expected_guard = guards[idx]
      assert_equal expected_guard.size, guard.args.size
      expected_guard.each do |name, cls|
        assert_equal cls, guard.arg(name).type.klass
      end
    end

    assert_equal effects.size, op.meta.effects.size
    op.meta.effects.each_with_index do |effect, idx|
      expected_effect = effects[idx]
      assert_equal expected_effect.size, effect.args.size
      expected_effect.each do |name, cls|
        assert_equal cls, effect.arg(name).type.klass
      end
    end
  end

  def test_sendResp
    op = Client.meta.operation("sendResp")
    do_test_op op, {:data => Payload}, [], []
  end

  def test_reqAuth
    op = ResourceOwner.meta.operation("reqAuth")
    do_test_op op, {:cred => Credential}, [{}], [{:client => Client}]
  end

  def test_reqAccessToken
    op = AuthServer.meta.operation("reqAccessToken")
    do_test_op op, {:authGrant => AuthGrant}, [{}], [{:client => Client}]
  end

  def test_reqResource
    op = ResourceServer.meta.operation("reqResource")
    do_test_op op, {:accessToken => AccessToken}, [{}], [{:client => Client}]
  end

  # def test_invokes
  #   assert_set_equal [:after],   ResourceOwner.meta.invokes.map(&:type)
  #   assert_set_equal [:reqAuth], ResourceOwner.meta.invokes.map(&:target_export)

  #   assert_set_equal [:after],          AuthServer.meta.invokes.map(&:type)
  #   assert_set_equal [:reqAccessToken], AuthServer.meta.invokes.map(&:target_export)

  #   assert_set_equal [:after],       ResourceServer.meta.invokes.map(&:type)
  #   assert_set_equal [:reqResource], ResourceServer.meta.invokes.map(&:target_export)

  #   assert_set_equal [:nondet, :nondet, :nondet],  Client.meta.invokes.map(&:type)
  # end

  # def test_to_als
  #   # just make sure it doesn't raise exceptions for now
  #   Alloy.meta.to_als
  # end
end
