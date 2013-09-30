require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :CookieReplay do

  abstract data Str
  data Addr < Str
  data Name < Str
  data Pair[n: Name, v: Str] < Str
  data AMap[entries: (set Pair)] < Str do
    fun get[k: Name][Str] {
      entries.select{|p| p.n == k }.v
    }
  end

  data URL[addr: Addr, queries: AMap] < Str
  data Cookie[domain: Addr, content: Pair] < Str
  data NameCookie < Name

  trusted Client [
    cookies: Addr ** Cookie
  ] do
    creates Cookie

    operation SetCookie[addr: Addr, cookie: Cookie] do      
      guard { cookies[addr] == cookie }
    end

    operation GetCookie[addr: Addr] do
      sends { User::Display[cookies[addr]] }
    end

    operation SendResponse[headers: AMap, body: Str] do 
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
      sends { Client::SendResponse }
    end
  end

  mod User do
    operation Display[text: Str] do end
    sends { Client::Visit }
  end

end
