require 'test_helper'
require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

view :OAuth do
  abstract_data Payload
  abstract_data AuthGrant < Payload

  data AuthCode     < AuthGrant

  data Credential   < Payload
  data AccessToken  < Payload
  data Resource     < Payload
  data OtherPayload < Payload

  data Addr

  data URI[addr: Addr, vals: (set Payload)]

  mod UserAgent do
    operation initFlow[redirectURI: URI] do
      affects(user: EndUser) { user.promptForCred }
    end

    operation enterCred[cred: Credential, uri: URI] do
      affects(client: ClientServer) { client.reqAuth(cred, uri) }
    end

    operation redirect[uri: URI] do
      affects(client: ClientServer) { client.sendAuthResp(uri) }
    end
  end

  mod EndUser, {
    cred: Credential
  } do
    creates Credential

    operation promptForCred[uri: URI] do
      affects(agent: UserAgent) { agent.enterCred(cred, uri) }
    end
  end

  mod ClientServer, {
    addr: Addr
  } do
    operation sendAuthResp[uri: URI]
    operation sendAccessToken[token: AccessToken]
    operation sendResource[data: Payload]

    # affects(agent: UserAgent) { agent.initFlow(addr) }
    # affects reqResource
    # affects reqAccessToken
  end

  mod AuthServer, {
    authGrants: Credential * AuthGrant,
    accessTokens: AuthGrant * AccessToken
  } do
    creates AuthGrant, AccessToken

    operation reqAuth[cred: Credential, uri: URI]  do
      guard { cred.in? authGrants.keys }

      # effects(agent: UserAgent) { agent.redirect URI.new(uri, [authGrants[cred]]) }
      affects(agent: UserAgent) {
        agent.redirect URI.some{ self.uri == uri && authGrants[cred].in?(self.vals) }
      }
    end

    operation reqAccessToken[authGrant: AuthGrant]  do
      guard                         { authGrant.in? accessTokens.keys }
      affects(client: ClientServer) { client.sendAccessToken(accessTokens[authGrant]) }
    end
  end

  mod ResourceServer, {
    resources: AccessToken * Resource
  } do
    creates Resource

    operation reqResource[accessToken: AccessToken]  do
      guard                         { accessToken.in? resources.keys }
      affects(client: ClientServer) { client.sendResource(resources[accessToken]) }
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
    assert_set_equal [Payload, OtherPayload, Credential, AuthCode, Addr,
                      URI, AuthGrant, AccessToken, Resource], oauth.data
  end

  def test_mod
    assert_set_equal [ClientServer, UserAgent, EndUser,
                      AuthServer, ResourceServer], oauth.modules
  end

  def assert_fields(actual, expected)
    assert_equal expected.size, actual.size
    expected.each do |name, type|
      fld = actual.find{|f| f.name.to_s == name.to_s}
      assert fld, "field `#{name}' not found"
      case type
      when Class
        assert_equal type, fld.type.klass, "types differ for field `#{name}'"
      when String
        assert_equal type, fld.type.to_s, "types differ for field `#{name}'"
      else
        fail "test error"
      end
    end
  end

  def test_fields
    assert_fields UserAgent.meta.fields, {}
    assert_fields EndUser.meta.fields,        :cred => Credential
    assert_fields ClientServer.meta.fields,   :addr => Addr
    assert_fields AuthServer.meta.fields,     :authGrants => "Credential -> AuthGrant",
                                              :accessTokens => "AuthGrant -> AccessToken"
    assert_fields ResourceServer.meta.fields, :resources => "AccessToken -> Resource"
  end

  def test_creates
    assert_set_equal [],                       UserAgent.meta.creates
    assert_set_equal [Credential],             EndUser.meta.creates
    assert_set_equal [],                       ClientServer.meta.creates
    assert_set_equal [AuthGrant, AccessToken], AuthServer.meta.creates
    assert_set_equal [Resource],               ResourceServer.meta.creates
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

  def test_UserAgent_ops
    op = UserAgent.meta.operation("initFlow")
    do_test_op op, {:redirectURI => URI}, [], [{:user => EndUser}]
    op = UserAgent.meta.operation("enterCred")
    do_test_op op, {:cred => Credential, :uri => URI}, [], [{:client => ClientServer}]
    op = UserAgent.meta.operation("redirect")
    do_test_op op, {:uri => URI}, [], [{:client => ClientServer}]
  end

  def test_EndUser_ops
    op = EndUser.meta.operation("promptForCred")
    do_test_op op, {:uri => URI}, [], [{:agent => UserAgent}]
  end

  def test_ClientServer_ops
    op = ClientServer.meta.operation("sendAuthResp")
    do_test_op op, {:uri => URI}, [], []
    op = ClientServer.meta.operation("sendAccessToken")
    do_test_op op, {:token => AccessToken}, [], []
    op = ClientServer.meta.operation("sendResource")
    do_test_op op, {:data => Payload}, [], []
  end

  def test_AuthServer_ops
    op = AuthServer.meta.operation("reqAuth")
    do_test_op op, {cred:Credential, :uri => URI}, [{}], [{:agent => UserAgent}]
    op = AuthServer.meta.operation("reqAccessToken")
    do_test_op op, {:authGrant => AuthGrant}, [{}], [{:client => ClientServer}]
  end

  def test_ResourceServer_ops
    op = ResourceServer.meta.operation("reqResource")
    do_test_op op, {:accessToken => AccessToken}, [{}], [{:client => ClientServer}]
  end

end
