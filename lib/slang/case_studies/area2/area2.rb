require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :Area2 do

  critical data Profile 
  data Token
  data FacultyID
  data StudentID

  trusted A2Site [
    profiles: (dynamic StudentID ** Profile),
    advisor: StudentID ** FacultyID,
    tokens: StudentID ** Token
  ] do

    op ViewProfile[id: StudentID, t: Token, ret: Profile] do
      guard { t == tokens[id] }
      effects { ret == profiles[id] }
    end

    op EditProfile[id: StudentID, t: Token, newProfile: Profile] do
      guard { t == tokens[id] }
      effects { self.profiles = self.profiles + id ** newProfile }
    end
  end

  many mod Faculty [
    id: FacultyID
  ] do
    sends { A2Site::ViewProfile }
    sends { A2Site::EditProfile }
  end

  many mod Student [
    id: StudentID
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
