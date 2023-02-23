/* This script prototypes an ambient pad sort of sound process*/
var process = PathName(thisProcess.nowExecutingPath);
var prog = process.fileName;
var path = process.pathOnly;
var main = 	(path+/+"setup.scd").load;

main.value {
	// 0.0 Define script-specific variables
	var w, screen, u, structs, setBounds, addStruct;
	var outNode, noteSeq, makeNode, playNode;
	var n, mpos;
	// 1.0 Load resources

	s.sync;

	//2.0 Create widget
	Window.closeAll;

	// 2.1 Configure window
	screen = Window.screenBounds;
	w = Window.new(
		"Pads",
		Rect(
			screen.width * 0.125,
			screen.height * 0.5,
			screen.width * 0.75,
			screen.height * 0.5
		)
	);

	w.background = Color.white;
	w.alwaysOnTop = true;

	u = UserView();

	//2.2 Define Node Struct Data
	//2.2a Define Array for storing Structs
	structs = [];

	//2.2b Define function for setting Struct boundaries in Window
	setBounds = { | struct, x, y |
		struct.bounds = Rect(x - 10, y - 10, 25, 25);
	};

	//2.2c Define Function creating Structs
	addStruct = { | x, y |
		var newStruct = IdentityDictionary.new;
		newStruct.add(\isClicked -> true);
		newStruct.add(\color -> Color.new(1.0.rand, 0, 1.0.rand));
		newStruct.add(\accent -> Color(0.0, 0.0, 0.0));
		//Define additional parameters within special functions
		newStruct.know = true;
		setBounds.value(newStruct, x, y);
		makeNode.value(newStruct);

		structs = structs.add(newStruct);

		// Sum outputs of each struct's node and send to system
		outNode[0] = {
			structs.collect { | n | n.node.ar }.sum
		};

		//Return amended Array of structs
		structs;
	};

	//2.3 Define UI Behavior
	//2.3a Represent structs as circles in UserView
	u.drawFunc = {
		structs.do { | item |
			Pen.use {
				var color, bounds, wbounds;

				Pen.color = item.color;
				Pen.circle(item.bounds);
				Pen.fillStroke;
			};
		};
	};

	//2.3b Define Mouse Actions
	u.mouseDownAction = { | v, x, y |
		var wasClicked = false;
		block { | break |
			structs.size.do { | index |
				var n = structs.size - index - 1;
				var item = structs[n];
				var b = item.bounds;
				var xtrue = false, ytrue = false;

				if ((x > (b.left - 24)) and: { x < (b.left + 24) }) {
					xtrue = true;
				};

				if ((y > (b.top - 24)) and: { y < (b.top + 24) }) {
					ytrue = true;
				};

				if (xtrue and: { ytrue }) {
					item.isClicked = true;
					wasClicked = true;

					playNode.value(item);

					break.value(999);
				};
			};

			/*if (wasClicked==false) {
			addStruct.value(x, y);
			}*/
		};
	};

	u.mouseMoveAction = { | v, x, y | };

	u.mouseUpAction = {
		structs.do { | item |
			item.isClicked = false;
		};
	};

	// 2.3c Make sure all structs are set to neutral
	u.mouseUpAction.value;

	// 3.0 Begin animating UI
	u.animate = true;
	u.frameRate = 30;

	// 4.0 Add UI to Window (dynamically)
	w.layout = HLayout(u);

	//5.0 Define Sound Data
	//5.1 Define final node in chain
	outNode = NodeProxy.audio(s, 2);
	outNode.play(0);

	outNode[8] = \filter -> { | in |
		var ffreq = \ffreq.kr(1500);
		var decay = \decay.kr(4);

		var sig = LPF.ar(in.sum / 2, ffreq);
		sig = DelayN.ar(sig, 0.2, 0.1.rand + 0.1);
		sig = CombN.ar(sig, 0.1, ({ Rand(0.01, 0.099) }!32), decay);
		sig = Splay.ar(sig);
		sig = LeakDC.ar(sig);
		5.do {
			sig = AllpassN.ar(sig, 0.1, ({ Rand(0.01, 0.099) }!2), decay * 3 / 4);
		};
		sig = LPF.ar(sig, ffreq);
		sig;
	};

	outNode.set(\wet8, 0.125);

	outNode[12] = \filter -> { | in | in.sin * -6.dbamp };

	makeNode = { | struct |
		var node, note;

		struct.add(\note -> [ 0, 2, 4, 5, 7, 9, 11 ].choose);
		struct.add(\node -> NodeProxy.audio(s, 2));

		struct.node[0] = Pbind(*[
			instrument: \saw,
			dur: Pexprand(2.0, 16.0, inf),
			timescale: [ 2.0, 4.0, 3.0, 5.0, 8.0 ].choose,

			degree: struct.note + [ 0.0, 0.005, 0.01 ],
			scale: Scale.minor,
			root: -4,
			mtranspose: Pfunc { mpos.next },

			octave: (struct.bounds.top / 500)
			.linlin(0.0, 1.0, 6.5, 2.0).asInteger,

			ffRLo: exprand(1.0, 2.0),
			ffRHi: exprand(0.9, 2.0),

			ffAtk: rrand(0.45, 0.55, inf),
			ffRelease: 1.0.rand,

			atk: exprand(0.0001, 0.2) + 0.00125,
			release: 1.0.rand + 0.4,
			curve: (-6, -5..(3)).choose,

			db: (-14..-18).choose - 5,

			pan: (struct.bounds.top / w.bounds.height) * 2 - 1
		]);

		outNode[0] = {
			structs.collect { | item |
				item.node.ar
			}.sum;
		};
	};

	// X.0 Present Window
	n = (16..32).choose;

	mpos = Pseq([
		Pseq([ 0, -2, ], 4).stutter(n),
		Pseq([ 0, 2, -1, 3 ], 4).stutter(n)
	], inf).asStream;

	n.do {
		var x, y;

		x = w.bounds.width.rand;
		y = w.bounds.height.rand;

		addStruct.value(x, y);
	};

	w.onClose = {
		fork {
			structs.do { | item |
				item.node.clear;
				item.amp.clear;
			};

			outNode.clear;

			s.sync;

			e.message("Nodes cleared.");

			if (thisProcess.argv.notEmpty) {
				exit(0);
			};
		};
	};

	w.front;
};
