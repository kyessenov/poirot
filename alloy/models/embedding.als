abstract sig Data {}
sig Prop {}
sig Addr extends Packet {
	props : set Prop
}
sig OtherPacket extends Packet {
	props : set Prop
}
abstract sig Packet extends Data {}

sig Op {
	addr : lone Addr,
	data : set OtherPacket,
	packets : set Packet
}{
	#addr.props = 3
	#data.props = 2
	packets = addr + data
}

run {
	some addr
} for 3


