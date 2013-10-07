require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :OAuth do

  abstract data Payload
  data AuthCode < Payload
  data AuthGrant < Payload
  data Credential < Payload
  data AccessToken < Payload 
  data Resource < Payload
  data ClientID < Payload
  data Scope < Payload

  data Addr
  data URI [addr: Addr, params: (set Payload)]

  critical Resource

  trusted EndUser, {
    cred: Credential
  } do
    creates Credential

    operation PromptForCred[uri: URI] do
      sends { UserAgent::EnterCred[cred, uri] }
    end
  end

  trusted UserAgent, { 
    knownClients: (set ClientID)
  } do
    assumption {
      # knownClients.all?{ |clientId| clientId.in? ClientServer.id }
      knownClients.in? ClientServer.id
    }

    operation InitFlow[redirect: URI, id: ClientID, scope: Scope] do
      guard { id.in? knownClients }
      sends { EndUser::PromptForCred[redirect] }
    end

    operation EnterCred[cred: Credential, uri: URI] do
      sends { AuthServer::ReqAuth[cred, uri] }
    end

    operation Redirect[uri: URI] do
      sends { ClientServer::SendAuthResp[uri] }
    end
  end

  trusted ClientServer, {
    addr: URI,
    id: ClientID,
    scope: Scope
  } do
    operation SendAuthResp[uri: URI]
    operation SendAccessToken[token: AccessToken]
    operation SendResource[res: Resource]

    sends { UserAgent::InitFlow[addr] }
    sends { ResourceServer::ReqResource }
    sends { AuthServer::ReqAccessToken }
  end

  trusted AuthServer, {
    authGrants: Credential ** AuthGrant,
    accessTokens: AuthGrant ** AccessToken
  } do
    creates AuthGrant, AccessToken

    operation ReqAuth[cred: Credential, uri: URI]  do
      guard { authGrants.key? cred }

      sends {
        UserAgent::Redirect() { |redirect|
          redirect.uri.addr == uri.addr and
          authGrants[cred].in?(redirect.uri.params)
        }
      }
    end

    operation ReqAccessToken[authGrant: AuthGrant]  do
      guard { accessTokens.key? authGrant }
      sends { ClientServer::SendAccessToken[accessTokens[authGrant]] }
    end
  end

  trusted ResourceServer, {
    resources: AccessToken ** Resource
  } do
    creates Resource

    operation ReqResource[accessToken: AccessToken]  do
      guard { resources.key? accessToken }
      sends { ClientServer::SendResource[resources[accessToken]] }
    end
  end
end
