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
    op SendReq[url: URL, headers: (set Pair)] do 
      sends { Browser::SendResp[responses[url]]}
    end
  end

  trusted Browser do
    op SendResp[resp: HTML, headers: (set Pair)] do 
      sends { User::DisplayHTML[resp] }
    end

    op Visit[url: URL] do
      sends { Server::SendReq[url] }
    end
  end

  mod User do
    op DisplayHTML[html: HTML] do end
    sends { Browser::Visit }
  end

end
