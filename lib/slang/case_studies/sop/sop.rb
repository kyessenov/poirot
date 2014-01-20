# model of the same origin policy

require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :SOP do
  
  abstract data Str
  data DOM < Str
  data HTML[dom: DOM] < Str
  data HTTPReq[headers: (set Str)]
  data HTTPResp[html: HTML, headers: (set Str)]
  global data Origin[domain: Domain]
  global data Domain
  global data Path
  global data URL[domain: Domain, path: Path]
  global data CookieScope[domain: Domain, path: Path]
  data Cookie < Str
  
  many mod Script [
    origin: Origin
  ] do    
    op AccessDOM[reqOrigin: Origin, ret: DOM] do
      guard { 
        # can only access DOM if the same origin
        origin == reqOrigin
      }
    end   
    
    sends { BrowserStore::GetCookie }
    sends { Script::AccessDOM }
    sends { HTTPServer::GET.some { |o| 
        # can only make req to the server with the same origin
        origin.domain == o.url.domain
      }
    }
    sends { HTTPServer::POST.some { |o| 
        # can only make req to the server with the same origin
        origin.domain == o.url.domain        
      }
    }
  end
  
  trusted BrowserStore [
    cookies: CookieScope ** Cookie
  ] do
    op GetCookie[cs: CookieScope, ret: Cookie] do
      guard { ret == cookies[cs] }
    end
  end

  many mod HTTPServer do
    op GET[url: URL, req: HTTPReq, ret: HTTPResp] 
    op POST[url: URL, req: HTTPReq, ret: HTTPResp]
  end

end
