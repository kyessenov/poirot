# model of the same origin policy

require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :Mashup do

  data AdPage  
  abstract data ProfileData
  critical data PrivateData < ProfileData
  data PublicData < ProfileData
  data ProfilePage[d: (set ProfileData)]
  global data UserID

  trusted AdClient do
    sends { AdServer::GetAd }
    sends { AdServer::SendInfo }
  end

  mod AdServer do
    op SendInfo[d: ProfileData]
    op GetAd[ret: AdPage]
  end

  trusted FBClient do
    sends { FBServer::GetProfile }
  end

  trusted FBServer [
    profileData: UserID ** ProfileData
  ] do
    op GetProfile[id: UserID, ret: ProfilePage] do
      guards {         
        # only sends back profile data that "id" maps to
        ret.d.in? (profileData[id])
      }
    end
  end

end
