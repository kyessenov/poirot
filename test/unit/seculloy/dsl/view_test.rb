require 'test_helper'
require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

view :OAuth do
  data Credential, AuthGrant, AccessToken, Resource

  mod ResourceOwner, {
    authGrants: Credential * AuthGrant
  } do
    creates AuthGrant

    # ---------- exports -----------

    def reqAuth(cred)
      # authGrants.keys.include? cred
      cred.in? authGrants.keys
    end

    # ---------- invokes -----------

    after :reqAuth do |cred, ans|
      Client.sendResp(authGrants[cred])
    end
  end

  mod Client, {
    cred: Credential
  } do
    creates Credential

    # ---------- exports -----------

    def sendResp(data)
    end

    # ---------- invokes -----------

    nondet { ResourceOwner.reqAuth }
    nondet { ResourceServer.reqResource }
    nondet { AuthServer.reqAccessToken }

  end

  mod AuthServer, {
    accessTokens: AuthGrant * AccessToken
  } do
    creates AccessToken

    # ---------- exports -----------

    def reqAccessToken(authGrant)
      authGrant.in? accessTokens.keys
    end

    # ---------- invokes -----------

    after :reqAccessToken do |authGrant, ans|
      Client.sendResp(accessTokens[authGrant])
    end
  end

  mod ResourceServer, {
    resources: AccessToken * Resource
  } do
    creates Resource

    # ---------- exports -----------

    def reqResource(accessToken)
      accessToken.in? resources.keys
    end

    # ---------- invokes -----------

    after :reqResource do |accessToken|
      Client.sendResp(resources[accessToken])
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
    assert_seq_equal [Credential, AuthGrant, AccessToken, Resource], oauth.data
  end

  def test_mod
    assert_seq_equal [ResourceOwner, Client, AuthServer, ResourceServer], oauth.modules
  end

  def test_fields
    assert_seq_equal ["authGrants"],   ResourceOwner.meta.fields.map(&:name)
    assert_seq_equal ["cred"],         Client.meta.fields.map(&:name)
    assert_seq_equal ["accessTokens"], AuthServer.meta.fields.map(&:name)
    assert_seq_equal ["resources"],    ResourceServer.meta.fields.map(&:name)
  end

  def test_creates
    assert_seq_equal [AuthGrant],   ResourceOwner.meta.creates
    assert_seq_equal [Credential],  Client.meta.creates
    assert_seq_equal [AccessToken], AuthServer.meta.creates
    assert_seq_equal [Resource],    ResourceServer.meta.creates
  end

  def test_exports
    assert_seq_equal [:reqAuth],        ResourceOwner.meta.exports.map(&:name)
    assert_seq_equal [:sendResp],       Client.meta.exports.map(&:name)
    assert_seq_equal [:reqAccessToken], AuthServer.meta.exports.map(&:name)
    assert_seq_equal [:reqResource],    ResourceServer.meta.exports.map(&:name)
  end

  def test_invokes
    assert_set_equal [:after],   ResourceOwner.meta.invokes.map(&:type)
    assert_set_equal [:reqAuth], ResourceOwner.meta.invokes.map(&:target_export)

    assert_set_equal [:after],          AuthServer.meta.invokes.map(&:type)
    assert_set_equal [:reqAccessToken], AuthServer.meta.invokes.map(&:target_export)

    assert_set_equal [:after],       ResourceServer.meta.invokes.map(&:type)
    assert_set_equal [:reqResource], ResourceServer.meta.invokes.map(&:target_export)

    assert_set_equal [:nondet, :nondet, :nondet],  Client.meta.invokes.map(&:type)
  end

  def test_to_als
    # just make sure it doesn't raise exceptions for now
    Alloy.meta.to_als
  end
end
