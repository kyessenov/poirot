# model of postMessage

require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :PostMessageComm do
  
  abstract data Str
  global data Origin
  
  many mod Script [
    origin: Origin
  ] do
    op PostMessage[data: Str, src: Origin, dest: Origin] do 
      guard { dest == origin }
    end
    
    sends { Script::PostMessage.some { |o| o.src == origin } }
  end

end
