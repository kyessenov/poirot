require 'slang/slang_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :HTTP do

  data Str
  data URL[addr: Str, query: Str]
  data HTML

  trusted Server [
    responses: URL ** HTML
  ] do
    operation SendReq[url: URL] do 
      sends { Client::SendResp[responses[url]]}
    end
  end

  trusted Client do
    operation SendResp[resp: HTML] do 
      sends { User::Display[resp] }
    end
    
    operation Visit[url: URL] do
      sends { Server::SendReq[url] }
    end
  end

  mod User do
    operation Display[resp: HTML] do end
    sends { Client::Visit }
  end

end
