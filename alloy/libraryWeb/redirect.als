module Redirect

open CookiePolicy

sig RedirectingReq in HTTPReq {
	dest : URL
}{
	sender in Browser
}

sig RedirectedReq in HTTPReq {
	from : RedirectingReq
}{
	sender in Browser
	from.@sender = sender
	args in from.@ret + from.@ret.encodes
	from in prevs
	url = from.dest
}

run {} for 3
