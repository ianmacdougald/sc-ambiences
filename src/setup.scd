/* This script boots the SuperCollider server*/
{ | func({}) |
	var name = PathName(thisProcess.nowExecutingPath).fileName;

	fork {
		var segment = {
			32.do { '-'.post };
			"\n".post;
		};

		var message = { | string |
			format("%: %", name, string).postln;
		};

		message.value("Setting up session...");
		segment.value;
		// 1.0 Define global variables
		message.value("Defining global variables in Environment 'e'...");
		e = e ? Environment.new;
		e.make {
			~out = ~out ? 0;

			~recPath = ~recPath ? (PathName(thisProcess.nowExecutingPath).pathOnly+/+"recordings");

			~cleanup = {
				while { currentEnvironment != topEnvironment } {
					currentEnvironment.pop
				};
				Buffer.freeAll;
			};

			~message = { | envir, string |
				format("%: %", name, string).postln;
			};

			~run = { | envir, path |
				var pn = PathName(path);
				var toSC;

				if (pn.extension=="scd") {
					//Throw error if anyone DARES to use these scripts on Windows
					//(jk...just don't know how Windows works anymore)
					Platform.case(
						\windows, { "Windows not supported. Sorry (not sorry).".throw }
					);

					//Get the path to the sclang executable
					toSC = PathName(Platform.resourceDir).pathOnly;

					"%/*/sclang %".format(toSC, path).unixCmd;
				};
			};
		};

		e.know = true;

		//2.0 Configure the server
		message.value("Configuring server...");

		"\t\ts.options.sampleRate = 48e3;".postln.interpret;
		"\t\ts.options.numInputBusChannels = 0;".postln.interpret;
		"\t\ts.options.numOutputBusChannels = 2;".postln.intrepret;
		"\t\ts.options.memSize = 2.pow(18);".postln.interpret;

		message.value("Booting server...");
		// 3.0 Book the server
		Server.killAll;

		s.waitForBoot {
			//4.0 Once the server is booted...

			//4.1 Define common SynthDef functions
			var envWrap = { | sig(SinOsc.ar(\freq.kr(400), \phase.kr(0))), timescale(\timescale.kr(1)) |
				var env;

				env = Env.perc(
					\atk.kr(0),
					\release.kr(1),
					1,
					\curve.kr(-4)
				).ar(Done.freeSelf, 1, timescale);

				sig = sig * env * \amp.kr(-12.dbamp);

				Pan2.ar(sig, \pan.kr(0));
			};

			var ffWrap = { | sig, freq(\freq.kr(400)),
				timescale(\timescale.kr(1)), filterClass(RLPF), qArg(\rq.kr(0.2)) |

				var lo, hi, ffEnv;

				lo = \ffRLo.kr(1.0);
				hi = \ffRHi.kr(8.0);

				ffEnv = Env.perc(
					\ffAtk.kr(0),
					\ffRelease.kr(1),
					1,
					\ffCurve.kr(-4)
				).ar(Done.none, 1, timescale);

				ffEnv = (lo + (ffEnv * (hi - lo))).abs;

				filterClass.ar(
					sig,
					(freq * ffEnv).clip(20.0, SampleRate.ir * 0.45),
					qArg
				);
			};

			s.sync;

			message.value("Defining SynthDefs...");
			//4.2 Define SynthDefs (adding them to the server)
			SynthDef(\varsaw, {
				var freq = \freq.kr(400);
				var timescale = \timescale.kr(1);
				var sig = LFSaw.ar(
					freq * LFTri.kr(
						\vibrate.kr(8)
					).unipolar(\vibdepth.kr(0.6)).midiratio
				);
				sig = sig + LFTri.ar(freq * 0.5);
				// sig = sig + SinOsc.ar(freq * 1.5, 0, 0.1);
				sig = sig + LPF.ar(
					LFPulse.ar(
						freq * 2,
						0,
						SinOsc.kr(
							ExpRand(1.05, 3.0) / timescale,
							Rand(0, pi)
						).unipolar(0.6) + 0.2,
						0.25
					),
					(freq * ExpRand(3, 6)).clip(0.1, 12e3)
				);
				sig = sig.sin;
				// sig = Limiter.ar(sig);
				sig = ffWrap.value(
					sig,
					freq,
					timescale,
					RLPF,
					1 - \q.kr(0.5)
				);

				Out.ar(
					\out.kr(0),
					envWrap.value(sig, timescale);
				)
			}).add;

			SynthDef(\dirtySine, {
				var freq = \freq.kr(400);
				var timescale = \timescale.kr(1);

				var sig, ampEnv;

				ampEnv = [
					Env([ 0, 1, ], [ 1 ]),
					Env([ 0, 1, 0 ], [ 1, 1, ].normalizeSum),
					Env([ 0, 1, 1, 0 ], [ 1, exprand(1, 10), 1].normalizeSum)
				].collect { | item |
					item.kr(
						Done.none,
						1,
						timescale * ExpRand(0.2, 2.0)
					) + 1.0 * ExpRand(1.05, 8.0)
				};

				ampEnv = TChoose.kr(
					Impulse.kr(0),
					ampEnv
				);

				ampEnv = TChoose.kr(
					Impulse.kr(0),
					[ ampEnv, SinOsc.kr(
						ExpRand(0.1 / timescale.reciprocal, 1.5 * timescale.reciprocal)) ]
				);

				sig = SinOsc.ar(freq) * (ampEnv + 1);
				sig = sig.fold(-1.0, 1.0);
				sig = sig.sin;
				sig = ffWrap.value(
					sig,
					freq,
					timescale,
					RLPF,
					1 - \q.kr(0.5)
				);

				OffsetOut.ar(
					\out.kr(0),
					envWrap.value(sig, timescale);
				);

			}).add;

			SynthDef(\saw, {
				var freq = \freq.kr(400);
				var timescale = \timescale.kr(1);
				var vibrato = LFTri.kr(\vibrate.kr(6)).unipolar(\vibdepth.kr(0.4)).midiratio;
				var sig;

				sig = sig = ffWrap.value(
					LFSaw.ar(freq * vibrato),
					freq,
					timescale,
					RLPF,
					1 - \q.kr(0.5)
				);

				OffsetOut.ar(
					\out.kr(0),
					envWrap.value(sig, timescale);
				);
			}).add;

			SynthDef(\tri, {
				var freq = \freq.kr(400);
				var timescale = \timescale.kr(1);

				var sig = LFTri.ar(freq * [ 1, 0.5, 0.25, Rand(1.0, 5.0).round(1.0) ] * LFTri.kr(ExpRand(1, 8))
					.unipolar(0.2).midiratio,
					mul: [ 2, 1, 0.5, 0.3 ].normalizeSum);
				sig = Splay.ar(sig, Rand(0.0, 1.0));
				sig = sig + PinkNoise.ar(\noiseamp.kr(0.2));
				sig = sig.sin;
				sig = LeakDC.ar(sig.flat);

				sig = sig = ffWrap.value(
					(sig * 0.5).sin,
					freq,
					timescale,
					RLPF,
					1 - \q.kr(0.5)
				);

				OffsetOut.ar(
					\out.kr(0),
					envWrap.value(sig, timescale);
				);
			}).add;

			s.sync;
			message.value("Load Buffers");

			 e.use {
				var toAudio;

				~buffers !? { ~buffers.asArray.do(_.free) };

				~buffers = IdentityDictionary.new;
				~buffers.know = true;

				toAudio = PathName(thisProcess.nowExecutingPath);
				toAudio = toAudio.pathOnly[0..(toAudio.pathOnly.size - toAudio.folderName.size - 2)];
				toAudio = PathName(toAudio+/+"audio");


				toAudio.files.do { | item |
					var name = item.fileNameWithoutExtension;
					~buffers.add(name.asSymbol
						-> Buffer.read(s, item.fullPath, action: { | b | b.normalize }));
				};
			};

			segment.value;
			message.value("Setup Complete.");

			Routine(func).play(AppClock);
		};
	};
};
