require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :CookieReplay do

  data Addr
  data Name
  data Value
  data Pair[n: Name, v: Value]
  data Cookie < Pair
  data URL[addr: Addr, queries: (set Pair)]

  trusted Server [
    sessions: URL ** Cookie
  ] do
    operation SendReq[url: URL, cookies: (set Cookie)] do
      guard { sessions[url].in? cookies }
      sends { Browser::SendResp }
    end
  end

  trusted Browser [ 
    cookies: (dynamic Addr ** Cookie)                 
  ] do    
    operation Visit[url: URL] do
      sends { Server::SendReq() { |op|
          op.url == url and
          op.cookies == cookies[url.addr]
        }
      }
    end

    operation SendResp[headers: (set Pair)] do end

    operation ExtractCookie[addr: Addr] do
      sends { User::Display[cookies[addr]] }
    end

    operation OverwriteCookie[addr: Addr, cookie: Cookie] do
      # in Alloy: should produce "cookies.post == cookies.pre + addr -> cookie"
      effects {
        # NOTE 
        #   `cookies = cookies + ...' 
        # doesn't work in Ruby when `cookies' is not a local variable
        #   `cookies' is a getter method, and 
        #   `cookies=' is a setter method
        # (this is not specific to our DSL, it's how it is in Ruby in general)
        self.cookies = self.cookies + addr ** cookie
      }
    end

  end
  
  mod User do
    operation Display[c: Cookie] do end
    sends { Browser::Visit }
    sends { Browser::ExtractCookie }
    sends { Browser::OverwriteCookie }
  end

  # abstract data Str
  # data Addr < Str
  # data Name < Str
  # data Pair[n: Name, v: Str] < Str
  # data AMap[entries: (set Pair)] < Str do
  #   fun get[k: Name][Str] {
  #     entries.select{|p| p.n == k}.v
  #   }
  # end
  
  # data URL[addr: Addr, queries: AMap] < Str
  # data Cookie[domain: Addr, content: Pair] < Str
  # data NameCookie < Name

  # trusted Client [
  #   cookies: (dynamic Addr ** Cookie)
  # ] do
  #   creates Cookie

  #   operation SetCookie[addr: Addr, cookie: Cookie] do
  #     #guard { cookies[addr] == cookie }

  #     # in Alloy: should produce "cookies.post == cookies.pre + addr -> cookie"
  #     effects {
  #       # NOTE 
  #       #   `cookies = cookies + ...' 
  #       # doesn't work in Ruby when `cookies' is not a local variable, but instead
  #       #   `cookies' is a getter method, and 
  #       #   `cookies=' is a setter method
  #       # (this is not specific to our DSL, it's how it is in Ruby in general)
  #       self.cookies = self.cookies + addr ** cookie
  #     }
  #   end
 
  #   operation GetCookie[addr: Addr] do
  #     sends { User::Display[cookies[addr]] }
  #   end

  #   operation SendResp[headers: AMap, body: Str] do
  #     sends { User::Display[body] }
  #   end

  #   operation Visit[url: URL] do
  #     sends { Server::SendReq() { |op|
  #         op.url == url and
  #         op.headers.get(NameCookie) == cookies[url.addr]
  #       }
  #     }
  #   end
  # end

  # trusted Server [
  #   session: URL ** Cookie
  # ] do
  #   operation SendReq[url: URL, headers: AMap] do
  #     sends { Client::SendResp }
  #   end
  # end

  # mod User do
  #   operation Display[text: Str] do end
  #   sends { Client::Visit }
  #   sends { Client::GetCookie }
  #   sends { Client::SetCookie }
  # end

end
