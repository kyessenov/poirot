# model of the same origin policy

require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :SOP do
  
  abstract data Text
  data DOM < Text
  data HTML[dom: DOM] < Text
  global data Origin
  global data Domain
  global data Path
  global data URL
  global data CookieScope[domain: Domain, path: Path]
  data Cookie < Text
  
  many mod Script [
    origin: Origin,
    doms: (set DOM)
  ] do
    op Resp[html: HTML, headers: (set Text)] do
      guard { doms.contains? (html.dom) }
    end
    
    op AccessDOM[reqOrigin: Origin, ret: DOM] do
      guard { 
        # can only access DOM if same origin
        origin == reqOrigin and
        doms.contains? (ret) 
      }
    end   

    sends { BrowserStore::GetCookie }
    sends { Script::AccessDOM }
    sends { HTTPServer::GET }
    sends { HTTPServer::POST }
  end
  
  trusted BrowserStore [
    cookies: CookieScope ** Cookie
  ] do
    op GetCookie[cs: CookieScope, ret: Cookie] do
      guard { ret == cookies[cs] }
    end
  end

  many mod HTTPServer do
    op GET[url: URL, headers: (set Text)] do
      sends { Script::Resp }
    end

    op POST[url: URL, headers: (set Text), params: (set Text)] do
      sends { Script::Resp }
    end 
  end

end
