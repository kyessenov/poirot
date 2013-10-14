require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :HTTP do

  data Addr 
  data Name
  data Value
  data HTML
  data Pair[n: Name, v: Value]
  data URL[addr: Addr, queries: (set Pair)]

  trusted Server [
    responses: URL ** HTML
  ] do
    operation SendReq[url: URL, headers: (set Pair)] do 
      sends { Client::SendResp[responses[url]]}
    end
  end

  trusted Client do
    operation SendResp[resp: HTML, headers: (set Pair)] do 
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
