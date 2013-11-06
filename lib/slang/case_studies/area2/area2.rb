require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :Area2 do

  data UserID
  critical data Token[encodes: UserID] 
  abstract data UserType
  one data TypeStudent < UserType
  one data TypeAdmin < UserType
  one data TypeFaculty < UserType
  data UserRecord [id: UserID, typ: UserType]
  critical data Profile[id: UserID]

  trusted A2Site [
     profiles: UserID ** Profile,
     userType: UserID ** UserType
  ] do
    assumption {
      # all uid: UserID, p: Profile do
      #   uid == p.id if profiles.contains?(uid ** p) 
      # end
      profiles.all? {|uid, p| p.id == uid }
    }

    creates Token
    creates Profile

    sends { DirectoryService::GetUserRecords }

    op ViewProfile[uid: UserID, token: Token, ret: Profile] do
      guard { 
        (userType[token.encodes] == TypeStudent and 
         ret.id == token.encodes) or
        userType[token.encodes] == TypeFaculty or
        userType[token.encodes] == TypeAdmin
      }
      effects { ret == profiles[uid] }
    end
  end
  
  trusted DirectoryService [
     userRecords: (dynamic set UserRecord)
  ] do
    op GetUserRecords[ret: (set UserRecord)] do
      effects { ret == self.userRecords }
    end
  end

  trusted Faculty [
    id: UserID,
    token: Token
  ] do
    sends { A2Site::ViewProfile }
  end

  mod Student [
    id: UserID,
    token: Token
  ] do
    sends { A2Site::ViewProfile }
  end

  trusted Admin [
    id: UserID,
    token: Token
  ] do
    sends { A2Site::ViewProfile }
  end

end
