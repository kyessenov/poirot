require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :OpenRedirector do
  data URI

  trusted User, {
    intents: (set URI)
  } do
    guard {
      not intents.contains?(MaliciousServer.addr)
    }

    sends { 
      Client::Visit() { |dest|
        dest.in? intents
      }
    } 
  end

  trusted Client do
    operation Visit[dest: URI] do
      sends {
        TrustedServer::HttpReq[dest] or
        MaliciousServer::HttpReq[dest]
      }
    end

    operation HttpResp[redirectTo: URI] do 
      sends {
        TrustedServer::HttpReq[redirectTo] or
        MaliciousServer::HttpReq[redirectTo]
      }
    end
  end

  trusted TrustedServer, {
    addr: URI
  } do
    operation HttpReq[addr: URI]

    sends { Client::HttpResp }
  end

  mod MaliciousServer, {
    addr: URI
  } do
    operation HttpReq[addr: URI]

    sends { Client::HttpResp }
  end

end

