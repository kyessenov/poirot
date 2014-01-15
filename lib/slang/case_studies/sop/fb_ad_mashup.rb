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
    op DisplayAd[ad: AdPage] 

    sends { AdServer::SendInfo }
  end

  mod AdServer do
    op SendInfo[d: ProfileData]

    sends { AdClient::DisplayAd }
  end

  trusted FBClient do
    op DisplayProfile[page: ProfilePage]

    sends { FBServer::GetProfile }
  end

  trusted FBServer [
    profileData: UserID ** ProfileData
  ] do
    op GetProfile[id: UserID] do
      sends { FBClient::DisplayProfile.some { |o| 
          # only sends profile data that "id" maps to
          o.page.d.in? (profileData[id])
        }
      }
    end
  end

end
