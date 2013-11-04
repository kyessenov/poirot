require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :Area2 do

  critical data Token
  data FacultyID
  data StudentID
  critical data Profile[id: StudentID]

  trusted A2Site [
    profiles: (dynamic StudentID ** Profile),
    advisor: StudentID ** FacultyID,
    tokens: StudentID ** Token
  ] do
    assumption {
      #TODO: Throws an error
      all s: StudentID, p: Profile do
        p.id == s if profiles.contains?(s ** p) 
      end
#      profiles.all? {|si, p| p.id == si }
    }

    creates Token
    creates Profile

    op ViewProfile[id: StudentID, t: Token, ret: Profile] do
      guard {  t == tokens[id] }
      effects { ret == profiles[id] }
    end

    op EditProfile[id: StudentID, t: Token, newProfile: Profile] do
      guard { t == tokens[id] }
      effects { self.profiles = self.profiles + id ** newProfile }
    end
  end

  trusted Faculty [
    id: FacultyID
  ] do
    sends { A2Site::ViewProfile }
    sends { A2Site::EditProfile }
  end

  mod Student [
    id: StudentID,
    token: Token
  ] do
    sends { A2Site::ViewProfile }
    sends { A2Site::EditProfile }    
  end

  trusted Admin [
  ] do
    sends { A2Site::ViewProfile }
    sends { A2Site::EditProfile }
  end

end
