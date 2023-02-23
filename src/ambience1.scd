/* This script prototypes an ambient pad sort of sound process*/
var process = PathName(thisProcess.nowExecutingPath);
var prog = process.fileName;
var path = process.pathOnly;
var main = 	(path+/+"setup.scd").load;

main.value {
	// 0.0 Define script-specific variables
	var w, screen, u, structs, setBounds, addStruct;
	var outNode, noteSeq, makeNode;
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

				bounds = item.bounds;
				wbounds = w.bounds;

				item.amp.bus.get { | value |
					item.accent.green = value.clip(0.0, 1.0);
					/*	item.accent.blue = 1 - (bounds.left / wbounds.width) / 2;
					item.accent.red = bounds.top / wbounds.height / 2;*/
				};

				color = item.color.deepCopy;
				if (item.isClicked.not) {
					color.green = (color.green + item.accent.green).clip(0.0, 1.0);
					// color.green.postln;
				} /* ELSE */ {
					/*				color = Color.new();
					color.red = (color.red + item.accent.red).clip(0.0, 1.0);
					color.green = (color.green + item.accent.green).clip(0.0, 1.0);
					color.blue = (color.blue + item.accent.blue).clip(0.0, 1.0);*/
				};

				Pen.color = color;
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
					break.value(999);
				};
			};

			if (wasClicked==false) {
				addStruct.value(x, y);
			}
		};
	};

	u.mouseMoveAction = { | v, x, y |
		structs.do { | item, index |
			if (item.isClicked) {
				setBounds.value(item, x, y);
				item.node.set(\pan, ((x / w.bounds.width) * 2 - 1).clip(-1.0, 1.0));

				//if the item is dragged offscreen
				if (((x < 0) or: { x > (w.bounds.width - 10) })
					|| ((y < 0) || (y > (w.bounds.height - 10)))) {
					var struct;

					//remove it
					struct = structs.removeAt(index);
					struct.node.release(1);
					struct.amp.clear;
				};

				u.refresh;
			}
		}
	};

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

	outNode[12] = \filter -> { | in | in.sin * -3.dbamp };

	noteSeq = Pxrand([ 0, 2, 4, 7, 9, 11 ], inf).asStream;

	makeNode = { | struct |
		var note = noteSeq.next;
		var node = NodeProxy.audio(s, 2);

		node[0] = Pbind(
			\instrument, \varsaw,
			\dur, [ 2.0, 4.0, 3.0, 5.0, 8.0 ].choose + 4.0,

			\degree, note +
			[ 0, [ 0.0, 0.005, 0.01 ] ].choose,

			\octave, Pfunc { (struct.bounds.top / 500).linlin(0.0, 1.0, 7.0, 2.0).asInteger },

			\timescale, Pkey(\dur) * Pexprand(1.1, 4.0, inf),

			\ffRLo, Pexprand(1.0, 2.0, inf),
			\ffRHi, Pexprand(0.9, 2.0, inf),

			\ffAtk, Pwhite(0.45, 0.55, inf),
			\ffRelease, 1 - Pkey(\ffAtk) * Pexprand(0.2, 1.0, inf),

			\atk, Pwhite(0.0, 0.2, inf) + rrand(0.4, 0.7),
			\release, 1 - Pkey(\atk),
			\curve, (-6, -5..(3)).choose,

			\db, (-14..-18).choose,
			\db, Pfunc { | ev |
				if (ev.degree.isCollection) {
					ev.db - 5;
				} { ev.db }
			},

			\pan, 0
		);

		node[1] = \filter -> { | in |
			Balance2.ar(
				in[0], in[1],
				\pan.kr((struct.bounds.left / w.bounds.width) * 2 - 1)
			);
		};

		struct.add(\node -> node);

		//Redefine node in order to track amplitude of signal
		node = NodeProxy.control(s, 1);
		node[0] = {
			var sig = struct.node.ar.sum;
			sig = sig * 2;
			sig = sig.sin;
			Latch.kr(PeakFollower.kr(sig, 0.998), Impulse.kr(16)).lag(0.125);
		};

		struct.add(\amp -> node);
	};

	// X.0 Present Window
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
