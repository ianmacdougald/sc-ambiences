/* What does this script do?
This script simulates a kind of pseudo-natural audio environment that focuses on small, discrete, almost insectoid sounds, representing a kind of intervention that invites you to change your mind rather than changing it for you, even pleasantly so.

It is meant to invoke curiosiosty and exploration as well as non-judgemental engagement with your senses. In other words, we can explore an alternative mode of listening to try to engender an altnerative state of mind
*/
var main = (PathName(thisProcess.nowExecutingPath).pathOnly+/+"setup.scd").load;

main.value {
	//Write your code here...
	// var buffer;
	//Load Resources
	~sig = NodeProxy.audio(s, 2);
	~sig.play;


	~sig[0] = {
		var buf = \buf.kr(e.buffers['minutia-src1'].bufnum);
		var irate = \irate.kr(40);
		var impulse = Impulse.ar(irate);
		var frames = BufFrames.kr(buf);
		var env = Env(
			[ 0, 1, 1, 0 ],
			[ 12, 105, 25 ].normalizeSum,
			\welch
		).ar(Done.none, impulse, 0.95 / irate);

		var sig = PlayBuf.ar(
			2,
			buf,
			BufRateScale.kr(buf) * \rate.kr(1),
			impulse,
			(frames * \start.kr(0.0).wrap(0.0, 1.0)).wrap(0, frames),
			1,
			Done.none
		);
		sig = LeakDC.ar(sig).sin;

		sig * \amp.kr(-3.dbamp)
	};

	~sig_irate_control = NodeProxy.control(s, 1);
	~sig_irate_control[0] = {
		LFNoise2.kr(LFNoise1.kr(0.1).exprange(0.2, 0.5))
		.exprange(4.0, 19.0)
	};

	~sig.map(\irate, ~sig_irate_control);

	~sig_start_control = NodeProxy.control(s, 1);
	~sig_start_control[0] = {
		LFSaw.kr(1 / 10).unipolar(0.1) + 0.35
	};

	~sig.map(\start, ~sig_start_control);

	~sig[2] = \filter -> { | in |
		var sig, fold;

		sig = PitchShift.ar(
			in,
			0.2,
			1,
			LFNoise2.kr(1).unipolar(0.5e-3),
			LFNoise2.kr(1.25).unipolar(0.5e-3)
		);

		fold = LFNoise2.kr(exprand(1.0, 3.0)).unipolar(2) + 1;

		sig = sig * (LFNoise2.kr(0.2).exprange(1.0, 8.0) + 1);
		sig = sig.fold(fold.neg, fold);
		LeakDC.ar(sig).sin * -18.dbamp
	};

	~sig[4] = \filter -> { | in | HPF.ar(in, 100) };

};
