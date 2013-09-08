require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :OAuth do
  abstract_data Payload
  abstract_data AuthGrant < Payload

  data AuthCode     < AuthGrant
  data Credential   < Payload
  data AccessToken  < Payload
  data Resource     < Payload
  data OtherPayload < Payload
  data Addr
  data URI[addr: Addr, params: (set Payload)]

  critical Resource

  trusted EndUser, {
    cred: Credential
  } do
    creates Credential

    operation PromptForCred[uri: URI] do
      sends { UserAgent::EnterCred[cred, uri] }
    end
  end

  trusted UserAgent do
    operation InitFlow[redirectURI: URI] do
      sends { EndUser::PromptForCred[redirectURI] }
    end

    operation EnterCred[cred: Credential, uri: URI] do
      sends { AuthServer::ReqAuth[cred, uri] }
    end

    operation Redirect[uri: URI] do
      sends { ClientServer::SendAuthResp[uri] }
    end
  end

  trusted ClientServer, {
    addr: Addr
  } do
    operation SendAuthResp[uri: URI]
    operation SendAccessToken[token: AccessToken]
    operation SendResource[data: Payload]

    sends { UserAgent::InitFlow[addr] }
    sends { ResourceServer::ReqResource }
    sends { AuthServer::ReqAccessToken }
  end

  trusted AuthServer, {
    authGrants: Credential * AuthGrant,
    accessTokens: AuthGrant * AccessToken
  } do
    creates AuthGrant, AccessToken

    operation ReqAuth[cred: Credential, uri: URI]  do
      guard { authGrants.key? cred }

      sends {
        UserAgent::Redirect() { |redirectUri|
          redirectUri.addr == uri.addr &&
          authGrants[cred].in?(redirectUri.params)
        }
      }
    end

    operation ReqAccessToken[authGrant: AuthGrant]  do
      guard { accessTokens.key? authGrant }
      sends { ClientServer::SendAccessToken[accessTokens[authGrant]] }
    end
  end

  trusted ResourceServer, {
    resources: AccessToken * Resource
  } do
    creates Resource

    operation ReqResource[accessToken: AccessToken]  do
      guard { resources.key? accessToken }
      sends { ClientServer::SendResource[resources[accessToken]] }
    end
  end
end
