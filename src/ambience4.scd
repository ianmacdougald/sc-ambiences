/* What does this script do?

*/
var main = (PathName(thisProcess.nowExecutingPath).pathOnly+/+"setup.scd").load;

main.value {
	//Write your code here...
	~sig = NodeProxy.audio(s, 2);
	~sig.play;

	~sig[1] = \filter -> { | in |
		RLPF.ar(
			in * 0.64,
			DelayN.kr(
				SinOsc.kr(0.05).exprange(1600, 7200),
				0.1,
				[ 0, 0.1 ]
			),
			0.2
		);
	};

	~sig[2] = \filter -> { | in |
		in = in * (SinOsc.kr(0.025).unipolar(SinOsc.kr(0.03125).unipolar(0.3) + 0.2) + 1.0);
		in = in.tanh;
		in;
	};

	~sig_wet1_map = NodeProxy.control(s, 1);
	~sig_wet1_map[0] = {
		LFNoise2.kr(0.1.rand).unipolar(0.8) + 0.2
	};

	~sig.map(\wet1, ~sig_wet1_map);

	~sig[3] = \filter -> { | in |
		var local = LocalIn.ar(2);

		in = Balance2.ar(
			in[0], in[1],
			LFNoise2.kr(0.05).bipolar
		);

		local = DelayC.ar(
			local + in,
			4.0 + ControlDur.ir,
			4.0 - ControlDur.ir
		);

		LocalOut.ar(local * LFNoise2.kr(0.1).exprange(0.5, 0.9));

		local;
	};

	~sig_wet3_map = NodeProxy.control(s, 1);
	~sig_wet3_map[0] = {
		LFNoise2.kr(0.02).unipolar(0.8) + 0.2
		* Line.kr(dur: 16.0);
	};

	~sig.map(\wet3, ~sig_wet3_map);

	~sig[8] = \filter -> { | in |
		var ffreq = LFNoise2.kr(0.03).exprange(900, 3000);
		var decay = LFNoise2.kr(0.04).exprange(2.0, 16.0);
		var sig = LPF.ar(in, ffreq);
		sig = DelayN.ar(sig, 0.3, (0.3.rand + 0.01).clip(0.0, 0.2999));
		sig = CombN.ar(sig, 0.1, ({ Rand(0.01, 0.099) }!32), decay);
		sig = Splay.ar(sig);
		sig = LeakDC.ar(sig);
		5.do {
			sig = AllpassN.ar(sig, 0.1, ({ Rand(0.01, 0.099) }!2), decay * 3 / 4);
		};
		sig = LPF.ar(sig, ffreq);
		sig;
	};

	~sig.set(\wet8, 0.5);

	/*~sig[11] = \filter -> { | in |
		CompanderD.ar(
			in,
			-24.dbamp,
			1.0,
			1 / 3,
			0.05,
			0.1
		) * 18.dbamp;
	};*/

	~sig[12] = \filter -> { | in |
		in = in * LFNoise2.kr(LFNoise1.kr(0.05).exprange(0.1, 0.5)).exprange(3.0, 7.0);
		LeakDC.ar(in).sin * -3.dbamp
	};

	~sig[0] = Pbind(
		\instrument, \tri,
		\root, 6,
		\degree, Pseq([ 0, 0, 0, 3, -2, -2, 0, 4, -4, -7, -7 ], inf),
		\degree, Pkey(\degree) + [ 0, 0.005, 0.01, 3, 5, 9 ],
		\dur, Pseq([ 4, 2, 2, 1, 1, 1, 1, 4, 4, 4 ], inf) * Pwhite(1.0, 2.0, inf) * 2,
		\timescale, Pkey(\dur) * Pwhite(1.0, 4.0, inf),
		\atk, Pwhite(0.5, 0.9, inf),
		\release, 0.2,
		\ffRLo, [ 1.8005, 1.5, 1.25, 1.125, 1.125 ] * Pwhite(0.9, 1.1, inf),
		\ffRHi, Pwhite(0.0, 2.0, inf) + [ 1.0, 0.5, 0.3, 0.3, 0.2 ],
		\ffAtk, 0.5,
		\ffRelease, Pwhite(0.0, 1.0, inf) + 0.1,
		\q, Pexprand(0.05, 0.84, inf),
		\amp, [ 3, 3, 3, 1, 1, 1 ].normalizeSum * 0.dbamp,
		\noiseamp, [ 0.2, 0.1, 0.1, 0.1, 0.1 ],
		\mtranspose, Pseq([ [ -7, -7, -7, 0, 0, 0 ], 3, 0, -2, [ -7, -7, -7, 0, 0, 0 ] ].rotate(0), 1).stutter(16),
		\mtranspose, Pseq([ 4, 4, -3, -3, 0, -2, -2 ], inf).stutter(8),
		\octave, [ 4, 4, 4, 5, 5, 5, 3, 3, 3 ] - 1,
		\vibrate, Pexprand(0.05, 0.75, inf),
		\vibdepth, Pexprand(1.0, 1.5, inf) - 1.0,
	);

};
