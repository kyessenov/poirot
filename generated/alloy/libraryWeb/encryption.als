module Encryption

open WebBasic

sig Key {}
sig Encrypted in Data {
	k : Key
}

sig OwnsKey in Module {
	owns : Key
}
sig Reader in Module {
	reads : set Data
}{
	reads in accesses.Op
}

fact {
	all m : Reader, d : m.reads |
		d in Encrypted implies
			m in OwnsKey and m.owns = d.k
}

pred ConfidentialityRead {
	no m : UntrustedModule, d : GoodData |
		d in m.reads
}

run {} for 3


