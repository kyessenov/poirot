require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :OpenID_Stateless do
  abstract data Payload

  data Credential   < Payload
  data OpenId       < Payload
  data OtherPayload < Payload

  data Addr
  data URI[addr: Addr, params: (set Payload)]

  critical OpenId

  trusted EndUser, {
    id: Addr,
    cred: Credential
  } do
    creates Credential

    operation PromptCredential[forId: Addr] do
      guard { forId == id }
      sends { UserAgent::EnterCred[cred, id] }
    end

    sends { RelyingParty::RequestLogIn[id] }
  end

  trusted UserAgent do
    operation RedirectToProvider[addr: Addr] do
      sends { IdentityProvider::RequestAuth[addr] }
    end

    operation RequestCredential[id: Addr] do
      sends { EndUser::PromptCredential[id] }
    end

    operation EnterCred[id: Addr, cred: Credential] do
      sends { IdentityProvider::ReceiveCred[id, cred] }
    end

    operation ReceiveOpenID[id: Addr, openId: OpenId] do
      sends { RelyingParty::LogIn[id, openId] }
    end

    operation LoginSuccessful
  end

  trusted RelyingParty do
    operation RequestLogIn[id: Addr] do
      sends { UserAgent::RedirectToProvider[id] }
    end

    operation LogIn[id: Addr, openId: OpenId] do
      sends { IdentityProvider::CheckAuth[id, openId] }
    end

    operation AuthVerified[id: Addr, openId: OpenId] do
      sends { UserAgent::LoginSuccessful }
    end
  end

  trusted IdentityProvider, {
    credentials: Addr * Credential,
    identities: Addr * OpenId
  } do
    operation RequestAuth[id: Addr] do
      guard { identities.key? id }
      sends { UserAgent::RequestCredential[id] }
    end

    operation ReceiveCred[id: Addr, cred: Credential] do
      guard { credentials.include? (id * cred) }
      sends { UserAgent::ReceiveOpenID[id, identities[id]] }
    end

    operation CheckAuth[id: Addr, openId: OpenId] do
      guard { identities.include? (id * openId) }
      sends { RelyingParty::AuthVerified[id, openId] }
    end
  end

end
