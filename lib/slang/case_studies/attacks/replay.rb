require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :ReplayAttack do
  data Packet

  many trusted EndPoint do
    creates Packet

    operation Deliver[packets: (set Packet)]

    sends { Channel::Transmit }
  end

  trusted Channel do
    operation Transmit[packets: (set Packet)]

    operation Probe[packets: (set Packet)] do
      sends { Eavesdropper::Emit }
    end

    sends { EndPoint::Deliver }
  end

  trusted Eavesdropper do
    operation Emit[packets: (set Packet)]

    sends { Channel::Probe }
  end
end
