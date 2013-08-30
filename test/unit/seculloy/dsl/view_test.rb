require 'test_helper'
require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

view :OAuth do
  data Credential, AuthGrant, AccessToken, Resource

  mod ResourceOwner, {
    authGrants: Credential * AuthGrant
  } do
  end

  mod Client, {

  } do
  end

  mod AuthServer, {
    accessTokens: AuthGrant * AccessToken
  } do
  end

  mod ResourceServer, {
    accessTokens: AccessToken * Resource
  } do
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
end
