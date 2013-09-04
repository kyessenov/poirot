# attack_eavesdropper.rb
# model of a network eavesdropper
#

require 'view.rb'

ep1 = mod :EndpointA do 
  creates :Packet
  exports(:deliverA,
          :args => [set(:data, :Packet)])
  invokes(:transmit)
end

channel = mod :Channel do
  exports(:transmit, 
          :args => [set(:data, :Packet)])
  exports(:probe,
          :args => [set(:data, :Packet)])
  invokes(:deliverA)
  invokes(:deliverB)
  invokes(:emit,
          :when => [triggeredBy(:probe)])
end

eavesdropper = mod :Eavesdropper do
  exports(:emit, 
          :args => [set(:data, :Packet)])
  invokes(:probe)
end

ep2 = mod :EndpointB do
  creates :Packet
  exports(:deliverB,
          :args => [set(:data, :Packet)])
  invokes(:transmit)
end

V_EAVESDROPPER = view :Eavesdropper do
  modules ep1, ep2, channel, eavesdropper
  trusted ep1, ep2, channel
  data :Packet
end

drawView V_EAVESDROPPER, "eavesdropper.dot"
dumpAlloy V_EAVESDROPPER, "eavesdropper.als"

