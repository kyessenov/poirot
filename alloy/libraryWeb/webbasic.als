module WebBasic

open generic/basic

-- basic datatypes
abstract sig Token extends Data {}
abstract sig Resource extends Data {
	encodes : set Data,
}{
	this not in encodes
}

abstract sig HTML extends Resource {
	links : set HTTPReq,
	script : lone Script
}
abstract sig XML extends Resource {}
abstract sig JSON extends Resource {}
-- resource may have additional complex structure
fact {
	all o : Op, r : Resource {
		r in o.args implies r.encodes in o.sender.accesses.o
		r in o.ret implies r.encodes in o.receiver.accesses.o + o.args + o.args.encodes
	}
}

abstract sig Protocol {}
one sig ProcHTTP, ProcHTTPS extends Protocol {}
abstract sig IP {}
sig Host in IP {}
abstract sig Port {}
abstract sig Path {}

abstract sig URL {
	protocol : Protocol,
	host : Host,
	port : lone Port,
	path : lone Path
}

abstract sig Origin {
	protocol : Protocol,
	host : Host,
	port : lone Port
}
fact OriginsAreCanonical {
	no disj o1, o2 : Origin {
		o1.protocol = o2.protocol
		o1.host = o2.host
		o1.port = o2.port
	}
}	

-- modules
abstract sig HttpServer extends Endpoint {
	host : Host,
	resources : URL -> Resource
}{
	host = addr	

	all o : this.receives[HTTPReq] {
		o.url.@host = host 
	}

	all o : this.receives[HTTPReq] | {
		o.ret & Resource in resources[o.url]
		-- no o.ret & {r : HTTPResp | r.resource not in resources[o.url] }
	}

	-- all URLs have the same domain
	all u : resources.Resource | u.@host = host	

	-- this.initAccess in resources[URL]
	no this.initAccess & (Resource - resources[URL])
}

abstract sig Frame {
	content : HTML lone -> Op,
	originalContent : HTML,
	host : Host,
	path : lone Path
}

abstract sig Endpoint extends Module {
	addr : IP
}

abstract sig Browser extends Endpoint {
	frames : Frame -> Op
}{
//	no (Data - (frames.html + frames.html.encodes)) & this.initAccess

	all o : this.receives[ReadDOM] | let f = o.frame {
		f in frames.o
		o.data in f.(content.o).encodes
	}

	all o : this.receives[WriteDOM] | o.frame in frames.o

	all f : Frame, o : Op |
		f -> o in frames implies 
			some o2 : this.hasSent[o, HTTPReq] |
				f.host = o2.url.host and f.path = o2.url.path and f.originalContent = o2.resource

	all f : Frame, h : HTML, o : Op |
		(f -> o in frames and h -> o in f.content) implies
			f.originalContent = h or
			some o2 : this.hasReceived[o, WriteDOM] | h = o2.newHTML and f = o2.frame
}

abstract sig Script extends Endpoint {
	context : lone Frame
}{
	no this.initAccess 
	all o : this.sends[DOMOp + BrowserOp] {
		context in o.receiver.frames.o
	}
	all o : this.sends[Op] {
		some (frames.o).context
	}	

	//this.initAccess in context.dom
}

-- DOM operations
//abstract sig DOMOp extends Op {
sig DOMOp in Op {
	frame : Frame
}{
	receiver in Browser
	sender in Script
}
sig ReadDOM in DOMOp {
	data : set Data
}{
	no args
	ret = data
}
sig WriteDOM in DOMOp {
	newHTML : HTML
}{	
//	args = newHTML
	newHTML in args
	no ret
}

-- server operations
//abstract sig HTTPReq extends Op {
sig HTTPReq in Op {
	url : URL,
	resource : lone Resource	// returned resource
}{
	receiver in HttpServer
	sender in Endpoint
	
	resource in ret
	no (Resource - resource) & ret
}
//abstract sig GET extends HTTPReq {}
//abstract sig POST extends HTTPReq {}
fact {
	no GET & POST
	HTTPReq = GET + POST

	no DOMOp & HTTPReq
	no HTTPReq & BrowserOp
	no BrowserOp & DOMOp
}

sig GET in HTTPReq {}
sig POST in HTTPReq {}
sig HTTPS in HTTPReq {}

fun xmlHTTPReq : set HTTPReq {
	{r : HTTPReq | 
		r.sender in Script}
}
sig XMLHTTPReq in HTTPReq {
}
fact {
	XMLHTTPReq = xmlHTTPReq
}

-- browser operations
//abstract sig BrowserOp extends Op {
sig BrowserOp in Op {
}{
	receiver in Browser
}

-- security assumptions
fact {
	all s : Script | s.context in originalContent.script.s
	no disj b1, b2 : Browser | 
		some b1.frames & b2.frames
}

-- commands
run {
	some DOMOp & SuccessOp
} for 3
