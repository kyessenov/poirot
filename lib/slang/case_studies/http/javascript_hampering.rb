require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :JavascriptHampering do

  data Addr
  data Name
  data Value
  data Script
  data HTML[script: Script]
  data Pair[n: Name, v: Value]
  data URL[addr: Addr, queries: (set Pair)]

  trusted Server [
    responses: URL ** HTML
  ] do
    op SendReq[url: URL, headers: (set Pair)] do 
      sends { Browser::SendResp[responses[url]]}
    end
  end

  many mod ScriptProc [
    original: HTML,
    transformed: HTML
  ] do
    op Exec[ret: HTML] do
      guard { ret == transformed }
    end
  end
  
  trusted Browser [
    transform: HTML * HTML
  ] do
    op SendResp[resp: HTML, headers: (set Pair)] do 
      sends { User::DisplayHTML[transform[resp]] }
      sends { ScriptProc::Exec[transform[resp]] }
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
