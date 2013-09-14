require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :OpenRedirector do
  data URI

  trusted User, {
    intents: (set URI)
  } do

    # assumption: the user doesn't intend to visit the malicious
    #             address
    assumption {
      not intents.contains?(MaliciousServer.addr)
    }

    # May invoke Client::Visit
    #
    # precondition: the user only visits intended addresses
    #               (those from +User.intents+)
    invokes {
      Client::Visit.some { |v|
        v.dest.in? intents
      }
    }
  end

  trusted TrustedServer, {
    addr: URI
  } do
    # accepts any requests
    operation HttpReq[addr: URI] do
      # sends +Client::HttpResp+ only in response to +HttpReq+
      response { Client::HttpResp }
    end
  end

  mod MaliciousServer, {
    addr: URI
  } do
    # accepts any requests
    operation HttpReq[addr: URI]

    # arbitrarily can send +Client::HttpResp+
    invokes { Client::HttpResp }
  end

  trusted Client do
    # the user initiates a connection
    operation Visit[dest: URI] do
      response {
        TrustedServer::HttpReq[dest] or
        MaliciousServer::HttpReq[dest]
      }
    end

    # receives a redirect header from the server
    operation HttpResp[redirectTo: URI] do
      response {
        TrustedServer::HttpReq[redirectTo] or
        MaliciousServer::HttpReq[redirectTo]
      }
    end

  end

end

