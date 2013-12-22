# model of the same origin policy

require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :Mashup do

  data AdPage  
  abstract data ProfileData
  data PrivateData < ProfileData
  data PublicData < ProfileData
  data ProfilePage[d: (set ProfileData)]

  mod AdClient do
    op DisplayAd[ad: AdPage] do
    end

    sends { AdServer::SendInfo }
  end

  mod AdServer do
    op SendInfo[d: ProfileData] do
    end

    sends { AdClient::DisplayAd }
  end

  trusted FBClient do
    op DisplayProfile[p: ProfileData] do
    end
  end

  trusted FBServer do
    sends { FBClient::DisplayProfile }
  end
end
