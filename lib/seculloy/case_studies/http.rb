require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :HTTP do

  abstract data Str
  data Addr < Str

  data URL[addr: Addr, queries: (set Str)]
  data HTTPReq[url: URL, headers: (set Str)] 
  data HTTPResp[body: Str]

  trusted Server do
    operation SendReq[req: HTTPReq] do 
      sends { Client::SendResp }
    end
  end

  trusted Client do
    operation SendResp[resp: HTTPResp] do end
    sends { Server::SendReq }                      
  end

end
