require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :Area2 do

  data UserID
  critical data Token[encodes: UserID]  
  abstract data UserType
  one data TypeStudent < UserType
  one data TypeAdmin < UserType
  one data TypeFaculty < UserType
  critical data Profile[id: UserID]

  trusted A2Site [
     profiles: UserID ** Profile,
     userType: UserID ** UserType
#     profiles: UserID ** Profile                 
  ] do
    assumption {
      all uid: UserID, p: Profile do
        uid == p.id if profiles.contains?(uid ** p) 
      end
    #   profiles.all? {|si, p| p.id == si }
    }

    creates Token
    creates Profile

    op ViewProfile[token: Token, ret: Profile] do
#      guard { 
      #  (userType[token.encodes] == TypeStudent and 
      #   ret.id == token.encodes) or
      #   userType[token.encodes] == Faculty or
      #   userType[token.encodes] == Admin
#      userType[token.encodes] == ret.id
#      }
#      effects { ret == profiles[token.encodes] }
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
