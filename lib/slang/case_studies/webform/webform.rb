require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :WebForm do

  data UserID  
  critical data UserRecord [id: UserID]
  data Form[data: UserRecord]
  data Page[form: Form]

  trusted WebStore [
     userRecords: UserID ** UserRecord
  ] do
    assumption {
      userRecords.all? {|uid, r| r.id == uid }
    }
    op GetFormPage[uid: UserID] do
      sends {
        AliceBrowser::SendPage() {|page|
          page.form == userRecords[uid]
        }
      }
    end
  end
  
  trusted AliceBrowser [
     aliceID: UserID
  ] do
    sends {
      WebStore::GetFormPage() { |uid| 
        uid == aliceID
      }      
    }
    op SendPage[page: Page] do
    end             
  end 
end
