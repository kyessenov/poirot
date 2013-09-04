# attack_replay.rb
# model of a network replay attacker
#

require 'view.rb'

ep = mod :Endpoint do 
  creates :Packet
  exports(:deliver,
          :args => [set(:packets, :Packet)])
  invokes(:transmit)
  setUniq false
end

channel = mod :Channel do
  exports(:transmit, 
          :args => [set(:packets, :Packet)])
  exports(:probe,
          :args => [set(:packets, :Packet)])
  invokes(:deliver)
  invokes(:emit,
          :when => [triggeredBy(:probe)])
end

eavesdropper = mod :Eavesdropper do
  exports(:emit, 
          :args => [set(:packets, :Packet)])
  invokes(:probe)
end

VIEW_REPLAY = view :Replay do
  modules ep, channel, eavesdropper
  trusted ep, channel
  data :Packet
end

drawView VIEW_REPLAY, "replay.dot"
dumpAlloy VIEW_REPLAY, "replay.als"

