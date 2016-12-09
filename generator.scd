(
var max_attention = 10;
var beat_tags = [\basebeat, \random, \offbeat, \break, \backbeat, \variation, \barline ];
// var harmony_tags = [\root, \variation, \drone];
var harmony_tags = [\drone, \root];

~all_instruments = [\bd, \clap, \hat, \bass, \pad, \bell, \fm_stab, \cymbal, \ride, \noise, \sampler ];
// ~all_instruments= [\noise];

~init_generation = {
	p = "C:/Users/mathi/Music/samples/909/hats/hh*.wav".pathMatch;
	~sample =  Buffer.read(s,p.choose).normalize;


	~default_attributes = (
		\bd: (\type: \rest, \sustain_time: 0.1.rrand(0.4), \amp: 1, \freq: 50.0.rrand(65.0), \release: 1.5.rrand(2.0), \distort: 0.0.rrand(0.6)),
		\sd: (\type: \rest, \amp: 0.4, \release: 0.02.rrand(0.2), \reverb: 0.001.exprand(0.05)),
		\clap: (\type: \rest, \amp: 0.7, \release: 0.05.exprand(0.15), \reverb: 0.1, \lfo: 10.0.rrand(60), \cutoff: 500.0.exprand(10e3)),
		\hat: (\type: \rest, \amp: 0.5, \attack: 1e-3, \release: 0.02.rrand(0.05), \cutoff: 5e3.rrand(15e3), \reverb: 0.04),
		\noise: (\type: \rest, \amp: 0.1, \cutoff: 1e3.rrand(1.5e3), \rez: 0.5.rand(0.7)),
		\ride: (\type: \rest, \release: 2.0.rrand(5), \amp: 0.1),
		\cymbal: (\type: \rest, \release: 2.0.rrand(8.0), \amp: 0.1, \reverb: 0.001.exprand(0.05)),
		\bass: (\type: \rest, \amp: 1, \freq: 50, \rez: 0.0.rrand(0.4), \filter_release: 0.01.exprand(1.0), \cutoff: 500.rrand(5e3), \sustain_time: 0.5, \legato: 4),
		\pad: (\type: \rest, \freq: 440, \amp: 1, \sustain_time: 2, \cutoff: 1e3.rrand(15e3), \env_type: 0, \reverb: 0.2),
		\fm_stab: (\type: \rest, \freq: 100, \amp: 0.05, \attack: 0.1, \release: 0.1.rrand(0.3), \detune: 0.5),
		\bell: (\type: \rest, \freq: 200.0.exprand(1200.0), \decay: 0.1.rrand(0.9), \amp: 0.1, \reverb: 0.0.rrand(0.1)),
		\sampler: (\type: \rest, \amp: 0.01, \release: 0.1.rrand(1.5), \distort: 0.0.rrand(0.6), \bufnum: ~sample.bufnum, \rate: 1)
	);

	~default_attention = (
		\bd: 0,
		\sd: 4,
		\clap: [2,5].choose,
		\hat: 1,
		\ride: [2,10].choose,
		\cymbal: 10,
		\bass: 5,
		\pad: [5,8,10].choose,
		\fm_stab: [8,10,12].choose,
		\bell: [2,5,10].choose,
		\sampler: 4

	);
	m = ~default_attention.values.asArray.maxItem/10;
	~default_attention.keysValuesChange({
		arg key , value;
		value/m;

	});
};

~generate = {
	arg tempo = 127, scale, root = 60, res = 32, bars = 1;
	var beat_tag;
	var harmony_tag;
	var instrument = ~all_instruments.choose;
	var attributes = ~default_attributes[instrument].copy;
	var attention = ~default_attention[instrument].copy;
	var index  = 0;
	var sustained = false;

	if (instrument == \bd, {
		beat_tag = [\basebeat, \variation].wchoose([6,1].normalizeSum);
		attributes[\type] = \note;
		attributes[\amp] = 1;

		if(beat_tag == \variation, {
			attributes[\amp] = 0.4;
			attention = 5;
		});
	});

	if (instrument == \sd, {
		beat_tag = \backbeat;
		attention = attention * 0.5.rrand(1.5);
		attributes[\type] = \note;
		attributes.keysValuesChange { |key, value| value * 0.5.rrand(1.5) };
	});

	if (instrument == \clap, {
		beat_tag = \backbeat;
		attention = attention * 0.5.rrand(1.5);
		attributes.keysValuesChange { |key, value| value * 0.5.rrand(1.5) };
		attributes[\release] = attributes[\release] * 0.5.exprand(3.0);
		attributes[\type] = \note;
		attributes[\amp] = 0.2;
	});

	if (instrument == \hat, {
		beat_tag = [\offbeat, \random, \n16th].choose;
		attention = attention * 0.5.rrand(1.5);
		attributes[\type] = \note;
		attributes.keysValuesChange { |key, value| value * 0.5.rrand(1.5) };
		attributes[\release] = attributes[\release] * 0.5.exprand(20);
		if (beat_tag == \random, {
			attention = 7;
		});
		if (beat_tag == \n16th, {
			attributes[\amp] = attributes[\amp] * 0.4;
			attention = 1;
		});
	});

	if (instrument == \noise, {
		beat_tag = \offbeat;
		attention = 0;
		// attributes.keysValuesChange { |key, value| value * 0.5.rrand(1.5) };
		attributes[\type] = \note;
		attributes[\amp] = 0.2;
	});

	if (instrument == \cymbal, {
		beat_tag = \barline;
		attention = attention * 0.5.rrand(1.5);
		attributes[\type] = \note;
		attributes.keysValuesChange { |key, value| value * 0.2.rrand(1.8) };
	});

	if (instrument == \ride, {
		beat_tag = \barline;
		attention = attention * 0.5.rrand(1.5);
		attributes[\type] = \note;
		attributes.keysValuesChange { |key, value| value * 0.2.rrand(1.8) };
	});


	if (instrument == \sampler, {
		beat_tag = [\offbeat, \n16th, \random].choose;
		attention = attention * 0.5.rrand(1.5);
		attributes[\type] = \note;
		attributes[\release] = attributes[\release] * 0.5.exprand(20);
		attributes[\amp] = 0.01* 0.9.rrand(1.1);
		attributes[\bufnum] = ~sample.bufnum;
		attributes[\rate] = 0.85.rrand(1.15);
		if (beat_tag == \random, {
			attention = 5;
		});
		if (beat_tag == \n16th, {
			attributes[\amp] = attributes[\amp] * 0.4;
			attention = 1;
		});
	});

	if (instrument == \bass, {
		beat_tag = [\variation, \offbeat, \basebeat].choose;
		attributes[\type] = \note;
		attention = attention * 0.5.rrand(1.5);
		attributes.keysValuesChange { |key, value| value * 0.5.rrand(1.5) };
		attributes[\freq] = scale.degreeToFreq(0.rrand(8), root.midicps, -3);
		attributes[\legato] = ({ arg i; 2**(i+3) } ! 3).choose;
		attributes[\cutoff] = 500.rrand(10e3);
		attributes[\amp] = 1;
		// attributes[\cutoff] = 500.rrand(5e3);

		if (beat_tag == \variation, {
			attention = attention * 3;
		});
	});

	if (instrument == \pad, {
		harmony_tag = [\root, \drone].choose;
		attributes[\type] = \note;
		if (harmony_tag == \drone, {
			var octave = [-1, 1].choose;
			var freqs = { scale.degreeToFreq((0..7).wchoose([ 10, 2, 5, 2, 5, 2, 5, 2 ].normalizeSum), root.midicps, octave) } ! 3;
			attributes.keysValuesChange { |key, value| value * 0.99.rrand(1.01) };
			attributes[\freq] = freqs;
			attributes[\amp] = 0.2;
			attributes[\sustain_time] = (2*bars).rand*60/tempo;
			attributes[\cutoff] = 400;
			attributes[\env_type] = 0;
			attention = attention * 0.25;
			beat_tag = \basebeat;
		});

		if (harmony_tag == \root, {
			var octave = [0, 1].choose;
			var freqs = { scale.degreeToFreq((0..7).wchoose([ 10, 2, 5, 2, 5, 2, 5, 2 ].normalizeSum), root.midicps, octave ) } ! 4;
			var amps = 0.5 ! 4;
			attributes.keysValuesChange { |key, value| value * 0.6.rrand(1.4) };
			attributes[\freq] = freqs;
			attributes[\amp] = amps;
			attributes[\sustain_time] = 0.25;
			attributes[\env_type] = 1;
			attention = attention * 0.5.rrand(1.5);
			beat_tag = [\variation, \backbeat].choose;
		});
	});

	if (instrument == \fm_stab, {
		beat_tag = [\basebeat, \variation].choose;
		attention = attention * 0.8.rrand(1.2);
		attributes.keysValuesChange { |key, value| value * 0.9.rrand(1.1) };
		attributes[\type] = \note;
		attributes[\freq] = scale.degreeToFreq(0.rrand(7), root.midicps, -2);
	});

	if (instrument == \bell, {
		beat_tag = [\offbeat, \random].choose;
		attention = attention * 0.5.rrand(1.5);
		attributes[\type] = \note;
		attributes.keysValuesChange { |key, value| value * 0.99.rrand(1.01) };
		if (beat_tag == \random, {
			attention = 15;
		});
	});

	if (beat_tag == \basebeat, {
		index = ((res/4) * (4*bars).rand);
	});

	if (beat_tag == \backbeat, {
		index = ((res/2) * (2*bars).rand + (res/4));
	});

	if (beat_tag == \offbeat, {
		index = ((res/4) * (4*bars).rand + (res/8));
	});

	if (beat_tag == \n16th, {
		index = ((res/8) * (8*bars).rand + (res/16));
	});

	if (beat_tag == \random, {
		index = res.rand;
	});

	if (beat_tag == \variation, {
		index = ((res/8) * (8*bars).rand + ((res/8).rand));
	});

	if (beat_tag == \barline, {
		index = 0;
	});

	(\instrument: instrument, \beat_tag: beat_tag, \sustained: sustained, \attention: attention, \attributes: attributes, \index: index)
};


~swingify = Prout({ |ev|
	var now, nextTime = 0, thisShouldSwing, nextShouldSwing = false, adjust;
	while { ev.notNil } {
		// current time is what was "next" last time
		now = nextTime;
		nextTime = now + ev.delta;
		thisShouldSwing = nextShouldSwing;
		nextShouldSwing = ((nextTime absdif: nextTime.round(ev[\swingBase])) <= (ev[\swingThreshold] ? 0)) and: {
			(nextTime / ev[\swingBase]).round.asInteger.odd
		};
		adjust = ev[\swingBase] * ev[\swingAmount];
		// an odd number here means we're on an off-beat
		if(thisShouldSwing) {
			ev[\timingOffset] = (ev[\timingOffset] ? 0) + adjust;
			// if next note will not swing, this note needs to be shortened
			if(nextShouldSwing.not) {
				ev[\sustain] = ev.use { ~sustain.value } - adjust;
			};
		} {
			// if next note will swing, this note needs to be lengthened
			if(nextShouldSwing) {
				ev[\sustain] = ev.use { ~sustain.value } + adjust;
			};
		};
		ev = ev.yield;
	};
});

)