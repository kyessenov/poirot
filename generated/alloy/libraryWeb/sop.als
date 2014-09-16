module SOP

open WebBasic

-- modules
sig SOPBrowser in Browser {
}{
	frames.Op in SOPFrame

	all o : this.receives[SOP_DOMOp] {
		-- SOP: only allowed to read DOM from the same origin
		o.senderOrigin = o.frame.origin
	}	
}

sig SOPFrame in Frame {
	origin : Origin,
}

fun scriptOrigin[s : Script] : Origin {
	let f = s.context |		-- frame that contains this origin
		f.origin
} 

sig SOPReq in HTTPReq {}

sig SOPScript in Script {}{
	all o : this.sends[SOPReq] {
		-- SOP: only allowed to make HTTP request (i.e. XMLHTTPReq) to the same origin
		o.url.host = context.origin.host
		o.url.protocol = context.origin.protocol
		o.url.port = context.origin.port
	}
	all o : this.sends[SOP_DOMOp] {
		o.senderOrigin = context.origin
	}
	context in SOPFrame
}

-- DOM operations
-- EK: Merging
sig SOP_DOMOp in DOMOp {
	senderOrigin : Origin
}

pred SOPProperty {
	no disj s1, s2 : Script |
		s1.context.origin != s2.context.origin and 
		mayAccess[s1, (s2.context).(content.Op).encodes]
}

fact assumptions {
	-- browser accepts an HTML and displays it inside a frame
	all b : Browser, o : b.sends[HTTPReq] {
		some o.resource implies {
			o.resource in HTML
	// TODO: Too strong?
	//		(some f : Frame | f.html = o.resource and f in b.frames)
		}
	}
	
//	no disj f1, f2 : Frame | f1.dom = f2.dom
}

-- commands
run {
	some DOMOp & SuccessOp
} for 3

check Confidentiality {
  Confidentiality
} for 2 but 4 Op, 8 Module, 8 Data

check SOPProperty {
	SOPProperty
} for 2 but 4 Op, 8 Module, 8 Data

