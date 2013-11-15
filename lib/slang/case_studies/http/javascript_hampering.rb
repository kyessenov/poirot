require 'slang/slang_dsl'
include Slang::Dsl

Slang::Dsl.view :JavascriptHampering do
  data Addr, Name, Value, HTML
  data Pair[n: Name, v: Value]
  data URL[addr: Addr, queries: (set Pair)]

  trusted Server [
    responses: URL ** HTML
  ] do
    op SendReq[url: URL, headers: (set Pair)] do 
      sends { Browser::SendResp[responses[url]]}
    end
  end

  many mod Script [
    original: HTML,
    transformed: HTML      
  ] do
    op Exec[resp: HTML, ret: HTML] do
      guard { resp == original and ret == transformed }
    end
  end

  trusted Browser [
    transform: HTML ** HTML
  ] do
    op SendResp[resp: HTML, headers: (set Pair)] do 
      sends { User::DisplayHTML[transform[resp]] }
      sends { Script::Exec[resp, transform[resp]] }
    end
    op Visit[url: URL] do
      sends { Server::SendReq[url] }
    end
  end
  
  mod User do
    op DisplayHTML[resp: HTML] do end
    sends { Browser::Visit }
  end
end
