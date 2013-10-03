require 'slang/slang_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :CookieReplay do

  abstract data Str
  data Addr < Str
  data Name < Str
  data Pair[n: Name, v: Str] < Str
  data AMap[entries: (set Pair)] < Str do
    fun get[k: Name][Str] {
      entries.select{|p| p.n == k}.v
    }
  end
  
  data URL[addr: Addr, queries: AMap] < Str
  data Cookie[domain: Addr, content: Pair] < Str
  data NameCookie < Name

  trusted Client [
    cookies: (dynamic Addr ** Cookie)
  ] do
    creates Cookie

    operation SetCookie[addr: Addr, cookie: Cookie] do
      #guard { cookies[addr] == cookie }

      # in Alloy: should produce "cookies.post == cookies.pre + addr -> cookie"
      effects {
        # NOTE 
        #   `cookies = cookies + ...' 
        # doesn't work in Ruby when `cookies' is not a local variable, but instead
        #   `cookies' is a getter method, and 
        #   `cookies=' is a setter method
        # (this is not specific to our DSL, it's how it is in Ruby in general)
        self.cookies = self.cookies + addr ** cookie
      }
    end

    operation GetCookie[addr: Addr] do
      sends { User::Display[cookies[addr]] }
    end

    operation SendResp[headers: AMap, body: Str] do
      sends { User::Display[body] }
    end

    operation Visit[url: URL] do
      sends { Server::SendReq() { |op|
          op.url == url and
          op.headers.get(NameCookie) == cookies[url.addr]
        }
      }
    end
  end

  trusted Server [
    session: URL ** Cookie
  ] do
    operation SendReq[url: URL, headers: AMap] do
      sends { Client::SendResp }
    end
  end

  mod User do
    operation Display[text: Str] do end
    sends { Client::Visit }
    sends { Client::GetCookie }
    sends { Client::SetCookie }
  end

end
