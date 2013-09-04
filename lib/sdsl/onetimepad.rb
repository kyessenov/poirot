# onetimepad.rb
#
require 'view.rb'

sender = mod :Sender do
  stores set(:resource, :Resource)
  stores :key, :Key
  creates :Resource
  creates :Ciphertext
  
  invokes(:send)
end

receiver = mod :Receiver do
  stores :key, :Key
  creates :Ciphertext

  exports(:send,
          :args => [:msg])
end

V_NETWORK = view :OneTimePad do
  modules sender, receiver
  trusted sender, receiver
  data :Resource, :Ciphertext
  critical :Resource
end

# drawView V_ONETIMEPAD
# dumpAlloy V_OENTIMEPAD
