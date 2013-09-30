require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :CookieReplay do
  data Cookie[domain: Addr, content: Pair]
  data Addr < Str
  data Name < Str
  data Value < Str
  data Pair[n: Name, v: Value] 
  data URL[addr: Addr, queries: (set Pair)]
  data Str

  trusted Client {
    cookies : Addr ** Cookie
  } do
    creates Cookie

    operation SetCookie[addr: Addr, cookie: Cookie] do
    end

    operation GetCookie[addr: Addr] do
      sends { User::Display[cookies[addr]] }
    end

    operation SendResponse[headers: (set Pair), body: Value] do 
      sends { User::Display[body] }
    end
  end


  trusted Server {
    session : URL ** Cookie
  } do
    operation SendReq[url: URL, headers: (set Pair)] do      
      sends { SendResponse }
    end
  end

  mod User do
    operation DisplayCookies[text : Str] do end
  end

end
