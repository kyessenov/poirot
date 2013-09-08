require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :OpenID_Stateless do
  abstract_data Payload

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
  end

  trusted UserAgent do
    operation RedirectToProvider[addr: Addr] do
      sends { IdentityProvider::Authenticate[addr] }
    end

    operation RequestCredential do
      sends { EndUser::PromptCredential[id] }
    end

    operation EnterCred[id: Addr, cred: Credential] do
      sends { IdentityProvider::ReqAuth[id, cred] }
    end

    operation ReceiveOpenID[id: Addr, openId: OpenID] do
      sends { RelyingParty::ReceiveOpenID[id, openId] }
    end

    operation LoginSuccessful
  end

  trusted RelyingParty do
    operation LogIn[id: Addr] do
      sends { UserAgent::RedirectToProvider[id] }
    end

    operation ReceiveOpenID[id, openId] do
      sends { IdentityProvider::CheckAuth[id, openId] }
    end

    operation AuthVerified[id, openId] do
      sends { UserAgent::LoginSuccessful }
    end
  end

  trusted IdentityProvider, {
    credentials: Addr -> Credential
    identities: Addr -> OpenID,
  } do
    operation Authenticate[id] do
      guard { identities.key? id }
      sends { UserAgent::RequestCredential[id] }
    end

    operation ReqAuth[id: Addr, cred: Credential] do
      guard { credentials.include? (id * cred) }
      sends { UserAgent::ReceiveOpenID[id, identities[id]] }
    end

    operation CheckAuth[id, openId] do
      guard { identities.include? (id * openId) }
      sends { RelyingParty::AuthVerified[id, openId] }
    end
  end

end
