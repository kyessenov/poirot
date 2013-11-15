require 'slang/slang_dsl'
include Slang::Dsl

Slang::Dsl.view :CookieReplay do
  data Addr, Name, Value
  data Pair[n: Name, v: Value]
  data Cookie < Pair
  data URL[addr: Addr, queries: (set Pair)]

  trusted Server [
    sessions: URL ** Cookie
  ] do
    op SendReq[url: URL, cookies: (set Cookie)] do
      guard { sessions[url].in? cookies }
      sends { Browser::SendResp }
    end
  end

  trusted Browser [ 
    cookies: (dynamic Addr ** Cookie)                 
  ] do    
    op Visit[url: URL] do
      sends { Server::SendReq() { |op|
          op.url == url and
          op.cookies == cookies[url.addr]
        }
      }
    end

    op SendResp[headers: (set Pair)]

    op ExtractCookie[addr: Addr, ret: Cookie] do
      guard { ret.in? cookies[addr] }
    end

    op OverwriteCookie[addr: Addr, cookie: Cookie] do
      effects { self.cookies = self.cookies + addr ** cookie }
    end
  end
  
  mod User do
    sends { Browser::Visit }
    sends { Browser::ExtractCookie }
    sends { Browser::OverwriteCookie }
  end
end
