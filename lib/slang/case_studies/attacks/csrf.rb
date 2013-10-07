require 'slang/slang_dsl'
require 'slang/model/operation'

include Slang::Dsl
include Slang::Model

Slang::Dsl.view :CSRF do

  abstract data Payload
  data Cookie       < Payload
  data OtherPayload < Payload

  data Hostname
  data Addr
  data URI[addr: Addr, params: (set Payload)]

  abstract data HtmlTag
  data ImgTag[src: URI] < HtmlTag

  data DOM[tags: (set HtmlTag)] < Payload

  trusted User, {
    intents: (set URI)
  } do
    sends {
      Client::Visit.some { |visit_op|
        visit_op.dest.in? intents
      }
    }
  end

  trusted TrustedServer, {
    cookies:      Operation ** Cookie,
    addr:         Hostname,
    protectedOps: (set Operation)
  } do
    creates DOM, Cookie

    operation HttpReq[cookie: Cookie, addr: URI] do
      guard {
        cookie == cookies[self] if protectedOps.contains?(self)
      }

      sends { Client::HttpResp }
    end
  end

  mod MaliciousServer, {
    addr: Hostname
  } do
    creates DOM

    operation HttpReq[cookie: Cookie, addr: URI] do
      sends { Client::HttpResp }
    end
  end

  trusted Client, {
    cookies: URI ** Cookie
  } do
    operation Visit[dest: URI] do
      sends {
        # TODO: CHECK what about some(cookies[dest])? e.g.
        #   c = Cookie.some { |c| c = cookies[dest] if some cookies[dest] }
        c = cookies[dest]
        TrustedServer::HttpReq[c, dest] or
        MaliciousServer::HttpReq[c, dest]
      }
    end

    operation HttpResp[dom: DOM, addr: URI] do
      sends {
        c = cookies[addr]
        a = URI.some { |u| u.in? dom.tags.src }
        TrustedServer::HttpReq[c, a] or
        MaliciousServer::HttpReq[c, a]
      }
    end
  end

end

