require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :JavascriptHampering do
  
  trusted Server [
    responses: URL ** HTML
  ] do
    operation SendReq[url: URL, headers: (set Pair)] do 
      sends { Browser::SendResp[responses[url]]}
    end
  end

  mod Script [
    
  ]

  trusted Browser [
  ] do
    operation SendResp[resp: HTML, headers: (set Pair)] do 
      sends { User::Display[resp] }
    end

    operation Visit[url: URL] do
      sends { Server::SendReq[url] }
    end
  end

  mod User do
    operation Display[resp: HTML] do end
    sends { Browser::Visit }
  end


end
