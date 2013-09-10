require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :EavesdropperAttack do
  data Packet

  trusted EndpointA do
    creates Packet

    operation DeliverA[data: (set Packet)]

    sends { Channel::Transmit }
  end

  trusted EndpointB do
    creates Packet

    operation DeliverB[data: (set Packet)]

    sends { Channel::Transmit }
  end

  trusted Channel do
    operation Transmit[data: (set Packet)]

    operation Probe[data: (set Packet)] do
      sends { Eavesdropper::Emit }
    end

    sends { EndpointA::DeliverA }
    sends { EndpointB::DeliverB }
  end

  trusted Eavesdropper do
    operation Emit[data: (set Packet)]

    sends { Channel::Probe }
  end
end
