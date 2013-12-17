require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :SharedHost do

  abstract data File
  data PublicFile <: File
  critical data PrivateFile <: File
  
  trusted HTTPServer [
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
  ] do
    sends {
      WebStore::GetFormPage() { |uid| 
        uid == aliceID
      }      
    }
    op SendPage[page: Page] do
    end             
  end 

  trusted FileSystem [
      
  ] do

  end
end
