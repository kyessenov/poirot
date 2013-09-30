require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :CookieReplay do

  abstract data Str
  data Addr < Str
  data Name < Str
  data Value < Str
  data Pair[n: Name, v: Value] < Str
  data URL[addr: Addr, queries: (set Pair)] < Str
  data Cookie[domain: Addr, content: Pair] < Str

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

    operation SendResponse[headers: (set Pair), body: Value] do 
      sends { User::Display[body] }
    end
  end


  trusted Server [
    session: URL ** Cookie
  ] do
    operation SendReq[url: URL, headers: (set Pair)] do      
      sends { Client::SendResponse }
    end
  end

  mod User do
    operation Display[text: Str] do end
  end

end
