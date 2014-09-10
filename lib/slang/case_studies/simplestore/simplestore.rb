require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :SimpleStore do

  data UID
  data PID # product ID
  data Cred # credentials

  component MyStore [
     userCreds: UID ** Cred,
     orders: (dynamic UID ** PID)
  ] do
    op Login[uid: UID, cred: Cred] do
      guard { cred == userCreds[uid] }
    end
  end

  component Customer [
    id: UID,
    cred: Cred
  ] do
    sends { MyStore::Login }
  end

end
