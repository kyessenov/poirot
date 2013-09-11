require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :OpenRedirector do
  data URI

  trusted User, {
    intents: (set URI)
  } do

    # assumption: the user doesn't intend to visit the malicious
    #             address
    guard {
      not intents.contains?(MaliciousServer.addr)
    }

    sends {
      Client::Visit.some { |v|
        # condition: the user only visits intended addresses 
        #            (those from +User.intents+)
        v.dest.in? intents
      }
    }
  end

  trusted TrustedServer, {
    addr: URI
  } do
    # accepts any requests
    operation HttpReq[addr: URI] {
      # sends +Client::HttpResp+ only in response to +HttpReq+
      sends { Client::HttpResp }
    }
  end

  mod MaliciousServer, {
    addr: URI
  } do
    # accepts any requests
    operation HttpReq[addr: URI]

    # arbitrarily can send +Client::HttpResp+
    sends { Client::HttpResp }
  end

  trusted Client do
    # the user initiates a connection
    operation Visit[dest: URI] do
      sends {
        TrustedServer::HttpReq[dest] or
        MaliciousServer::HttpReq[dest]
      }
    end

    # receives a redirect header from the server
    operation HttpResp[redirectTo: URI] do
      sends {
        TrustedServer::HttpReq[redirectTo] or
        MaliciousServer::HttpReq[redirectTo]
      }
    end
  end

end

