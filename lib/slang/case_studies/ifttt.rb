require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view(:IFTTT) do
  data Payload
  data TID, PID
 
  trusted component IFTTT [
    recipes: TID ** AID,
  ] {
    operation Notify[tid: TID, payload: Integer] {
      guard    { currCounter < limit }
    }
  }

end
