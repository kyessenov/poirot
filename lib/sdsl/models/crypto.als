module crypto[Data]

/**
	* Library of crypto functions
	*/
sig Key {}

one sig Crypto {
	enc : Data -> Key -> Data
}

fun encrypt[d : Data, k : Key] : Data {
	Crypto.enc[d][k]
}

fun decrypt[d : Data, k : Key] : Data {
	Crypto.enc.d.k
}

