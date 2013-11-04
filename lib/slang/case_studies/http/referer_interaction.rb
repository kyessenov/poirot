require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :RefererInteraction do

  data Addr
  data Name
  data Value
  data Pair[n: Name, v: Value]
  data URL[addr: Addr, queries: (set Pair)]
  data HTML[links: (set URL)]
  data RefererHeader < Pair

  trusted Server [
    responses: URL ** HTML
  ] do
    op SendReq[url: URL, headers: (set Pair)] do 
      sends { Browser::SendResp[responses[url]]}
    end
  end
  
  trusted Referer [
    responses: URL ** HTML
  ] do
    op SendReq[url: URL, headers: (set Pair)] do 
      sends { Browser::SendResp[responses[url]]}
    end
  end

  trusted Browser [
  ] do
    op SendResp[resp: HTML, headers: (set Pair)] do 
      sends { User::DisplayHTML[resp] }
    end

    op FollowLink[url: URL] do
      sends { Server::SendReq[url] }
    end

    op Visit[url: URL] do
      sends { Server::SendReq[url] }
      sends { Referer::SendReq[url] }
    end
  end

  mod User [
  ] do
    op DisplayHTML[html: HTML] do 
      sends { Browser::FollowLink() {|o| o.url.in? html.links} }
    end
    sends { Browser::Visit }
  end

end
