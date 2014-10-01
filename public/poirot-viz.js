/**
 * Visualizer for Poirot
 */
var vis, dbViz, editor;
var w = 700, h = 450;
var cmpW = 120, cmpH = 80;
var cmpRx = 10, cmpRy = 10;
var opSize = 12;
var bordercolor = "grey";
var border = "1px";
var colorTrusted = "#ccc";
var colorMalicious = "rgb(246, 127, 127)";
var currOp = -1;
var currCmp = null;

var hasTuple = function(lst, t){
    var i;
    for (i = 0; i < lst.length; ++i) 
	if (JSON.stringify(lst[i]) == JSON.stringify(t)) return lst[i];
    return false;
};

var indent = function(str) {
    return "\u00A0\u00A0\u00A0" + str;
}

var cmpCenterX = function(x) { return x + (cmpW/2.0); };
var cmpCenterY = function(y) { return y + (cmpH/2.0); };

var mkInvArglst = function(evt){
    var argnames = [];
    var retnames = []
    var j;
    for (j = 0; j < evt.args.length; ++j){
    	argnames.push(evt.args[j]);
    }
    for (j = 0; j < evt.ret.length; ++j){
	retnames.push(evt.ret[j]);
    }
    if (argnames.length < 1) {
	if (retnames.length < 1) {
	    return "";
	} else {
	    return "[ ] : " + retnames.join(",");
	}
    }
    if (retnames.length < 1){
	return "[" +  argnames.join(",") + "]";
    }
    return "[" +  argnames.join(",") + "] : " + retnames.join(",");
};

var drawInvLabel = function(invLabel){
    var invEvt = invLabel.datum().rep;
    invLabel.text(mkInvArglst(invEvt));
};

var hideInvLabel = function(invLabel){ invLabel.text(""); };

    // The table generation function
    function tabulate(data, columns) {
    	var table = dbViz.append("table")
            .attr("class", "pure-table")
            .attr("style","margin-top:1"),
        thead = table.append("thead"),
        tbody = table.append("tbody");

    	// append the header row
    	thead.append("tr")
            .selectAll("th")
            .data(columns)
            .enter()
            .append("th")
            .text(function(column) { return column; });

    	// create a row for each object in the data
    	var rows = tbody.selectAll("tr")
            .data(data)
            .enter()
            .append("tr");

    	// create a cell in each row for each column
    	var cells = rows.selectAll("td")
            .data(function(row) {
    		return columns.map(function(column) {
                    return {column: column, value: row[column]};
    		});
            })
            .enter()
            .append("td")
            .attr("style", "font-family: Courier") // sets the font style
            .html(function(d) { return d.value; });
	
    	return table;
    };

var delDuplicates = function(lst) {
    var newlst = [];
    $.each(lst, function(i, el){
	if($.inArray(el, newlst) === -1) newlst.push(el);
    });
    return newlst;
};

var displayAttackFound = function() {
    var text = "An attack scenario has been found!"
    dbViz.append("div").attr("class", "db-text")
	.text(text);    
}

var displaySampleScenarioGenerated = function() {
    var text = "A sample scenario has been generated."
    dbViz.append("div").attr("class", "db-text")
	.text(text);    
}

var displayCurrOpInfo = function(events) {
//	{inst: "Op0", type: "HTTPReq", args: ["d0"], 
//	 ret: ["d1"], sender: "Browser0", receiver: "Server0"},

    if (currOp >= 0){
	var text = "In Step " + (currOp + 1) + ",";
	var i;
	for (i = 0; i < events.length; i++){	   
	    var e = events[i];
	    if (e.inst == ("Op" + currOp)) {
		var senderText = e.sender.substring(0, e.sender.length - 1);
		var receiverText = e.receiver.substring(0, e.receiver.length - 1);
		text += " " + senderText + " invokes " + e.type + 
		    " on " + receiverText + " with:";
		dbViz.append("div").attr("class", "db-text")
		    .text(text);
		text = "Arguments: [" + e.args.join(",") + "]"
		dbViz.append("div").attr("class", "db-text")
		    .text(indent(text));
		if (e.ret.length > 0) {
		    text = "Return data: " + e.ret[0]	    
		} else {
		    text = "No return data"
		}
		dbViz.append("div").attr("class", "db-text")
		    .text(indent(text));
		break;
	    }
	}
    }
}

var displaySpecialData = function(data) {
    dbViz.append("div").attr("class", "db-text")
	.text("Initial configuration for Customer:");
    dbViz.append("div").attr("class", "db-text")
	.text(indent("myId: " + data.myId));
    dbViz.append("div").attr("class", "db-text")
	.text(indent("myPwd: " + data.myPwd));
    
    dbViz.append("div").attr("class", "db-text")
	.text("Initial configuration for MyStore:");
    var i;
    var tuples = [];
    for (i = 0; i < data.passwords.length; ++i){
	var p = data.passwords[i]
	if (p.op == "Op0") {
	    tuples.push("(" + p.uid + "," + p.pwd + ")");
	}
    }
    dbViz.append("div").attr("class", "db-text")
	.text(indent("passwords: [" + tuples.join(",") + "]"));

    tuples = [];
    for (i = 0; i < data.sessions.length; ++i){
	var p = data.sessions[i];
	if (p.op == "Op0") {
	    tuples.push("(" + p.uid + "," + p.sid + ")");
	}
    }
    dbViz.append("div").attr("class", "db-text")
	.text(indent("sessions: [" + tuples.join(",") + "]"));

    tuples = [];
    for (i = 0; i < data.orders.length; ++i){
	var p = data.orders[i];
	if (p.op == "Op0") {
	    tuples.push("(" + p.uid + "," + p.oid + ")");
	}
    }
    dbViz.append("div").attr("class", "db-text")
	.text(indent("orders: [" + tuples.join(",") + "]"));    
}

var displayInfo = function(cmp, accesses, events, specialData) {
    var text;
    var i;
    var data = [];
    clearDBViz();
    
    for (i = 0; i < accesses.length; ++i){
	var c = accesses[i].cmp;
	var d = accesses[i].data;
	var o = accesses[i].op;
	if (c == cmp.inst){
	    if (currOp < 0) data.push(d)
	    else {
		var n = o[o.length - 1];
		if (n <= currOp) data.push(d)
	    }
	}
    }
    data = delDuplicates(data)
    text = cmp.type;
    if (currOp >= 0) {
	displayCurrOpInfo(events);
    } else if (!jQuery.isEmptyObject(specialData)){
	displaySpecialData(specialData);
    }

    currCmp = cmp;
};

var sampleInst = {
    cmps: [
	{inst: "Server0", type: "Server", trusted: true},
	{inst: "Server1", type: "Server", trusted: false},
	{inst: "Browser0", type: "Browser", trusted: true},
	{inst: "Browser1", type: "Browser", trusted: false},
	{inst: "User0", type: "User", trusted: true},
	{inst: "User1", type: "User", trusted: false}
    ],     
    data : [
	{inst: "d0", type: "TypeA"},
	{inst: "d1", type: "TypeA"},
	{inst: "d2", type: "TypeB"},
	{inst: "d3", type: "TypeB"},
	{inst: "d4", type: "TypeC"},
	{inst: "d5", type: "TypeC"}
    ],
    events : [
	{inst: "Op0", type: "HTTPReq", args: ["d0"], 
	 ret: ["d1"], sender: "Browser0", receiver: "Server0"},
	{inst: "Op1", type: "HTTPReq", args: ["d1", "d2"], 
	 ret: ["d3"], sender: "Browser1", receiver: "Server0"},
	{inst: "Op2", type: "VisitPage", args: [], 
	 ret: ["d4"], sender: "User0", receiver: "Browser0"},
	{inst: "Op3", type: "VisitPage", args: ["d3"], 
	 ret: [], sender: "User1", receiver: "Browser1"},
	{inst: "Op4", type: "HTTPReq", args: ["d2"], 
	 ret: ["d3"], sender: "Browser1", receiver: "Server1"}
    ],
    database : [
    	{"UserID": "UserID0", "Key": "Key2"}, 
	{"UserID": "UserID1", "Key": "Key1"}
    ]
};

var findObj = function(objs, inst) {
    var i;
    for (i=0; i < objs.length; i++)
	if (objs[i].inst == inst) return objs[i];
    return null;
};

var drawInst = function(inst){
    drawTrace(inst);
    drawDB(inst.database);
};

var drawDB = function(database) {
    tabulate(database, ["UserID", "Key"]);
};

var clearViz = function(){
    vis.selectAll("*").remove();
};
var clearDBViz = function(){
    dbViz.selectAll("*").remove();
    currCmp = null;
};

var drawTrace = function(inst){

    cmps = inst.cmps;
    data = inst.data;
    events = inst.events;
    fields = inst.fields;
    console.log(fields);
    accesses = inst.accesses;   
    specialData = inst.specialData;

    var lastEventIdx = events.length - 1;
    clearViz();
    clearDBViz();
    currOp = -1;

    var ops = [];
    var exports = [];
    var invokes = [];
    for (i=0; i < events.length; ++i){
	var e = events[i];
	var receiverCmp = findObj(cmps, e.receiver);
	var senderCmp = findObj(cmps, e.sender);
	var t = {type: e.type, receiver: receiverCmp};
	var j, invk;
	var op = hasTuple(ops, t);
	var invk = ({source: senderCmp, target: t});

	if (!op) {
	    exports.push({source: receiverCmp, target: t});
	    ops.push(t);
	} else {
	    invk.target = op;
	}
	invk.rep = e;
	invokes.push(invk);
    }
    
    var nodes = cmps.concat(ops);
    var links = exports.concat(invokes);

    // build the arrow.
    vis.append("svg:defs").selectAll("marker")
    	.data(["mid"])      // Different link/path types can be defined here
    	.enter().append("svg:marker")    // This section adds in the arrows
    	.attr("id", String)
    	.attr("viewBox", "0 -5 10 10")
    	.attr("markerWidth", 8)
    	.attr("markerHeight", 8)
    	.attr("orient", "auto")
    	.append("svg:path")
    	.attr("d", "M0,-5L10,0L0,5");

    // add force layout
    // var force = d3.layout.force()
    // 	.nodes(nodes)
    // 	.links(links)
    // 	.size([w, h])
    // 	.linkDistance(function (d) {
    // 	    if ($.inArray(d, invokes) != -1) {
    // 		return 200;
    // 	    } else {
    // 		return 50;
    // 	    }
    // 	})
    // 	.charge(-400)
    // 	.start();

    var force = cola.d3adaptor()
        .nodes(nodes) 
        .links(links) 
        .linkDistance(function(d) {
	    if ($.inArray(invokes, d))
		return 100;
	    else
		return 50;
	})
        .size([w, h]).start(); 

    // export lines
    var expset = vis.selectAll("#exports")
    	.data(exports)
    	.enter()
    	.append("line")
    	.style("stroke-width", 7)
	.style("stroke", function(d) { 
    	    return (d.source.trusted? colorTrusted : colorMalicious)});

    // add invocation paths
    var invset = vis.selectAll("#invokes")
    	.data(invokes)
    	.enter()
    	.append("svg:path")
    	.attr("marker-mid", "url(#mid)")
    	.attr("id", function(d) {
    	    return "inv_" + d.rep.inst;
    	})
    	.attr("fill", "none")
    	.style("stroke", "black");


    // add labels on invocation paths
    var invlabels = [];
    for (i=0; i < invset[0].length; ++i){
    	var inv_id = invset[0][i].id;
    	var inv_data = vis.select("#" + inv_id).datum();
    	var inv_evt = inv_data.rep;
    	var label = vis.append("text")
    	    .style("font-size", "16px")
    	    .append("textPath")
    	    .attr("xlink:href", "#" + inv_id)
    	    .attr("startOffset", "25%")
    	    .append("tspan")
    	    .attr("dy", -7)
            .datum(inv_data);
    	invlabels[inv_id.slice(-1)] = label;
    	//drawInvLabel(label);
    }

    // components
    var cmpset = vis.selectAll("#cmpset")
    	.data(cmps)
    	.enter().append("g").attr("class", "cmp")
	.call(force.drag);
    
    cmpset.append("svg:rect")
    	.attr("width", cmpW)
    	.attr("height", cmpH)
    	.attr("rx", cmpRx)
    	.attr("ry", cmpRy)
    	.attr("fill", function(d) {
	    return (d.trusted ? colorTrusted : colorMalicious) })
    	.attr("class", "rectCmp")
        .on("click", function(d) {
	    d.fixed = true;
	    displayInfo(d, accesses, events, specialData);
	});

    cmpset.append("text")
    	.attr("x", 5)
    	.attr("y", cmpH - 10)
    	.text(function(d) {return d.type});

    //operations
    var opset = vis.selectAll("#opset")
    	.data(ops)
    	.enter().append("g").attr("class", "op").call(force.drag);
    
    opset.append("svg:circle")
    	.attr("r", opSize)
    	.attr("fill", function(d) { 
    	    return (d.receiver.trusted? colorTrusted : colorMalicious)})
        .on("click", function(d) {d.fixed = true});

    opset.append("text")
    	.text(function(d) {return d.type})
        .attr("dy", 20);
    
    // fix dragged node
    function myDragstart(d) {
    	d3.select(this).classed("fixed", d.fixed = true);
    };
    var drag = force.drag().on("dragstart", myDragstart);

    force.on("tick", function() {
    	// from component to op
    	expset.attr("x1", function(d) { return cmpCenterX(d.source.x); })
    	    .attr("y1", function(d) { return cmpCenterY(d.source.y); })
    	    .attr("x2", function(d) { return d.target.x; })
    	    .attr("y2", function(d) { return d.target.y; });
    	// from op to component
    	invset.attr("d", function(d) {
    	    var srcX = cmpCenterX(d.source.x);
    	    var srcY = cmpCenterY(d.source.y);
    	    var dstX = d.target.x;
    	    var dstY = d.target.y;
    	    var dx = srcX + (dstX - srcX)/2;
    	    var dy = srcY + (dstY - srcY)/2;
    	    return "M" + srcX + " " + srcY +
    		" L" + dx + " " +  dy +
    		" L" + dstX + " " +  dstY;
    	});
	// components
    	cmpset.attr("transform", function(d) {
            return "translate(" + d.x + "," + d.y + ")";});
	// operations
    	opset.attr("transform", function(d) {	   
            return "translate(" + d.x + "," + d.y + ")";});
    }); 
    var highlight = function() {
    	if (currOp >= 0) {
    	    invset.style("stroke", function(d) {
    	    	if (d.rep.inst == ("Op" + currOp)) return "black";
    	    	else return "lightgrey";
    	    });
    	    invset.style("stroke-width", function(d) {
    	    	if (d.rep.inst == ("Op" + currOp)) return "2";
    	    	else return "1";
    	    });
    	    invset.style("marker-mid", function(d) {
    	    	if (d.rep.inst == ("Op" + currOp)) return "url(#mid)";
    	    	else return "none";
    	    });
    	    for (i=0; i < invlabels.length; ++i){
    	    	if (i == currOp) drawInvLabel(invlabels[i]);
    	    	else hideInvLabel(invlabels[i]);
    	    }

	    if (currCmp != null)
		displayInfo(currCmp, accesses, events, specialData);
    	} else {
	    for (i=0; i < invlabels.length; ++i){
    		hideInvLabel(invlabels[i]);
    	    }
    	    invset.style("stroke", "black")
		.style("stroke-width", 1)
		.style("marker-mid", "url(#mid)");
	    if (currCmp != null)
		displayInfo(currCmp, accesses, events, specialData);
    	}
    };
    var doPrev = function() {
    	if (currOp >= 0) {
    	    currOp = currOp - 1;
    	    highlight();
    	}
    };
    var doNext = function() {
    	if (currOp < lastEventIdx) {
    	    currOp = currOp + 1;
    	    highlight();
    	}
    };
    d3.select("#prev").on("click", doPrev);
    d3.select("#next").on("click", doNext);
};

var initPoirot = function(){
    var i;
    vis	= d3.select("#graph").append("svg");
    vis.attr("width", w).attr("height", h);
    vis.text("Our Graph").select("#graph");

    // add border around svg
    var borderPath = vis.append("rect")
	.attr("x", 0)
	.attr("y", 0)
	.attr("height", h)
	.attr("width", w)
	.style("stroke", bordercolor)
	.style("fill", "none")
	.style("stroke-width", 0);

    /**
     * Database
     */
    dbViz = d3.select("#database");

    editor = ace.edit("editor");
    editor.getSession().setMode("ace/mode/ruby");

    $("#run").click(function(e) {
	$("#loading").show();
	$.ajax({type: "POST", 
		url: "/run",
		data: { model: editor.getSession().getValue() },
		success: function(result){ 
		    var inst = JSON.parse(result);
		    drawTrace(inst);
		    $("#loading").hide();
		}
	       });
    });

    $("#analyze").click(function(e) {
	$("#loading").show();
	$.ajax({type: "POST", 
		url: "/analyze",
		data: { model: editor.getSession().getValue() },
		success: function(result){ 
		    var inst = JSON.parse(result);
		    drawTrace(inst);
		    $("#loading").hide();
		}
	       });
    });

};
