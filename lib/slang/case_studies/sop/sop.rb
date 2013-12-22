# model of the same origin policy

require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :SOP do
  
  data DOM
  data HTML[dom: DOM]
  data Origin
  data Domain
  data Path
  data URL
  data ReqHeader
  data RespHeader
  data Param
  data CookieScope[domain: Domain, path: Path]
  data Cookie
  
  many mod Script [
    origin: Origin,
    doms: (set DOM)
  ] do
    op Resp[html: HTML, headers: (set RespHeader)] do
      guard { doms.contains? (html.dom) }
    end
    
    op AccessDOM[reqOrigin: Origin, ret: DOM] do
      guard { 
        # can only access DOM if same origin
        origin == reqOrigin 
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
    op GET[url: URL, headers: (set ReqHeader)] do
      sends { Script::Resp }
    end

    op POST[url: URL, headers: (set ReqHeader), params: (set Param)] do
      sends { Script::Resp }
    end 
  end

end
