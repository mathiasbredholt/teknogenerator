(
var beat_tags = [\basebeat, \random, \offbeat, \break, \backbeat, \variation, \barline ];
// var harmony_tags = [\root, \variation, \drone];
var bar_tags = [\all, \variation];
~attention_scale = 0.2;
~all_instruments = [\bd, \noise, \chords, \hat, \hat909, \clap909, \fm_stab, \bell, \bass, \ride, \fm_stab ];

~init_generation = {
    p = ((File.getcwd.replace("\\", "/") ++ "/hats/hh*.wav").pathMatch ++
        (File.getcwd.replace("\\", "/") ++ "/hats/oh*.wav").pathMatch).choose;
    // p = p.fileName;
    // ~sample =  Buffer.read(s,"C:/Users/mathi/Music/samples/909/hats/"++p).normalize;
    ~hats =  Buffer.read(s, p).normalize;

    p = (File.getcwd.replace("\\", "/") ++ "/claps/f9clp*.wav").pathMatch.choose;
    // p = p.fileName;
    // ~sample =  Buffer.read(s,"C:/Users/mathi/Music/samples/909/hats/"++p).normalize;
    ~claps =  Buffer.read(s, p).normalize;


    ~default_attributes = (
        \bd: (\type: \rest, \sustain_time: 0.08.rrand(0.25), \amp: 1, \freq: 50.0.rrand(60.0), \release: 1.5.rrand(2.0), \distort: 0.0.rrand(0.6)),
        \sd: (\type: \rest, \amp: 0.4, \release: 0.02.rrand(0.2), \reverb: 0.001.exprand(0.05)),
        \clap: (\type: \rest, \amp: 0.7, \release: 0.05.exprand(0.15), \reverb: 0.1, \lfo: 10.0.rrand(60), \cutoff: 500.0.exprand(10e3)),
        \hat: (\type: \rest, \amp: 0.5, \attack: 1e-3, \release: 0.02.rrand(0.05), \cutoff: 5e3.rrand(15e3), \reverb: 0.0.rrand(0.4)),
        \noise: (\type: \rest, \amp: 0.1, \cutoff: 1e3.rrand(1.5e3), \phase: 0.rrand(1), \teeth: 5.rrand(60), \rez: 0.5.rand(0.7)),
        \ride: (\type: \rest, \release: 2.0.rrand(5), \amp: 0.1),
        \cymbal: (\type: \rest, \release: 2.0.rrand(8.0), \amp: 0.1, \reverb: 0.001.exprand(0.05)),
        \bass: (\type: \rest, \amp: 1, \freq: 50, \rez: 0.0.rrand(0.2), \filter_release: 0.01.exprand(1.0), \cutoff: 500.rrand(5e3), \legato: 4),
        \chords: (\type: \rest, \freq: 440, \amp: 1, \sustain_time: 0.0.rrand(0.25), \filter_release: 0.02.rrand(0.1), \cutoff: 0.8e3.rrand(3e3), \env_type: 0, \reverb: 0.2),
        \fm_stab: (\type: \rest, \freq: 100, \amp: 0.05, \attack: 1e-3, \release: 0.08.rrand(0.3), \detune: 0.5),
        \bell: (\type: \rest, \freq: 200.0.exprand(1200.0), \decay: 0.1.rrand(0.9), \amp: 0.1, \reverb: 0.0.rrand(0.7), \delay: 0.0.rrand(0.7)),
        \hat909: (\type: \rest, \amp: 0.01, \sustain_time: 0.1.rrand(0.5), \distort: 0.0.rrand(0.6), \bufnum: ~hats.bufnum, \rate: 1),
        \clap909: (\type: \rest, \amp: 0.01, \sustain_time: 0.1.rrand(0.5), \distort: 0.0.rrand(0.6), \bufnum: ~claps.bufnum, \rate: 1)
    );

    ~default_attention = (
        \bd: 0,
        \sd: 4,
        \clap: [ 2, 5].choose,
        \hat: 1,
        \ride: [2,10].choose,
        \cymbal: 10,
        \bass: 3,
        \chords: [4,8].choose,
        \fm_stab: [3, 10].choose,
        \bell: [2,5,10].choose,
        \clap909: 2,
        \hat909: 2
    );

    m = ~default_attention.values.asArray.maxItem/~attention_scale;
    ~default_attention.keysValuesChange({
        arg key , value;
        value/m;
    });

    ~root_seq = [ 0 ] ++ ({ -5.rrand(5) } ! 1);
    ~scale_seq = { [Scale.minor, Scale.major].choose } ! ~root_seq.size;
};

~generate = {
    arg tempo = 127, scale, root = 60, res = 32, bars = 1;
    var beat_tag;
    var bar_tag = \whole;
    var instrument = ((\bd ! 8) ++ (\hat ! 10) ++ (\hat909 ! 4) ++ ~all_instruments).choose;
    var attributes = ~default_attributes[instrument].copy;
    var attention = ~default_attention[instrument].copy;
    var index  = 0;
    var sustained = false;

    if (instrument == \bd, {
        beat_tag = [\basebeat, \variation].wchoose([10,1].normalizeSum);
        attributes[\type] = \note;
        attributes[\amp] = 1;
        attention = 0;

        if(beat_tag == \variation, {
            attributes[\amp] = 0.4;
            attention = ~attention_scale * 4;
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
        bar_tag = [\whole, \variation].choose;
        attention = attention * 0.5.rrand(1.5);
        attributes[\type] = \note;
        attributes.keysValuesChange { |key, value| value * 0.5.rrand(1.5) };
        attributes[\release] = attributes[\release] * 0.5.exprand(2);
        if (beat_tag == \random, {
            attention = attention * 8;
            attributes[\amp] = attributes[\amp] * 0.1;
        });
        if (beat_tag == \n16th, {
            attributes[\amp] = attributes[\amp] * 0.2;
            attention = attention * 0.1;
        });
    });

    if (instrument == \noise, {
        beat_tag = \offbeat;
        attention = 0;
        // attributes.keysValuesChange { |key, value| value * 0.95.rrand(1.05) };
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


    if (instrument == \hat909, {
        beat_tag = \offbeat;
        // attention = attention * 0.5.rrand(1.5);
        attributes[\type] = \note;
        // attributes[\amp] = 0.01 * 0.5.rrand(1.5);
        attributes[\bufnum] = ~hats.bufnum;
        attributes[\rate] = 0.98.rrand(1.02);
        if (beat_tag == \random, {
            attention = 5;
        });
        if (beat_tag == \n16th, {
            attributes[\amp] = attributes[\amp] * 0.4;
            attention = 1;
        });
    });

    if (instrument == \clap909, {
        beat_tag = \backbeat;
        attention = attention * 0.5.rrand(1.5);
        attributes[\type] = \note;
        attributes[\amp] = 0.05 * 0.5.rrand(1.5);
        attributes[\bufnum] = ~claps.bufnum;
        attributes[\rate] = 0.98.rrand(1.02);
    });

    if (instrument == \bass, {
        var k = ~root_seq.choose;
        beat_tag = [\offbeat, \variation].choose;
        attributes[\type] = \note;
        attention = attention * 0.5.rrand(1.5);
        attributes.keysValuesChange { |key, value| value * 0.5.rrand(1.5) };
        attributes[\freq] = Scale.minor.degreeToFreq(0, (root+k).midicps, -2);
        attributes[\legato] = ({ arg i; 2**(i+1) } ! 2).choose;
        attributes[\cutoff] = 100.rrand(0.5e3);
        attributes[\amp] = 1;
        bar_tag = \root;
        if (k != 0, {
            bar_tag = \variation;
        });
        // attributes[\cutoff] = 500.rrand(5e3);

        if (beat_tag == \variation, {
            attention = attention * 2;
        });
    });

    if (instrument == \chords, {
        // harmony_tag = [\root, \drone].choose;
        // if (harmony_tag == \drone, {
        //     var octave = [-1, 1].choose;
        //     var freqs = { scale.degreeToFreq((0..7).wchoose([ 10, 2, 5, 2, 5, 2, 5, 2 ].normalizeSum), root.midicps, octave) } ! 3;
        //     attributes.keysValuesChange { |key, value| value * 0.99.rrand(1.01) };
        //     attributes[\freq] = freqs;
        //     attributes[\amp] = 0.2;
        //     attributes[\sustain_time] = (2*bars).rand*60/tempo;
        //     attributes[\cutoff] = 400;
        //     attributes[\env_type] = 0;
        //     attention = attention * 0.25;
        //     beat_tag = \basebeat;
        // });

        // if (harmony_tag == \root, {
        // var n = 1.rrand(5);/
        var n = 8;
        var octave = [0, 1].choose;
        // var scale = [ Scale.minor, Scale.major ].choose;
        var k = ~root_seq.size.rand;
        var freqs = (0, 2..[8, 10, 12, 14].choose).collect { arg degree; ~scale_seq[k].degreeToFreq(degree, (root + ~root_seq[k]).midicps, 0); };
        var amps = 0.5 / n;

        bar_tag = \root;
        if (k != 0, {
            bar_tag = \variation;
        });
        attributes.keysValuesChange { |key, value| value * 0.5.rrand(1.5) };
        attributes[\freq] = freqs;
        attributes[\amp] = amps;
        attributes[\sustain_time] = 60/Tempo.bpm * [ 1/8, 1/4, 1/2 ].choose;
        beat_tag = [\variation, \backbeat ].choose;
        if (beat_tag == \variation, {
            attention = attention * 5;
        });
        attributes[\type] = \note;

    });

    if (instrument == \fm_stab, {
        var k = ~root_seq.choose;
        beat_tag = [\variation, \backbeat].choose;
        attention = attention * 0.8.rrand(1.2);
        attributes.keysValuesChange { |key, value| value * 0.9.rrand(1.1) };
        attributes[\type] = \note;
        attributes[\freq] = Scale.minor.degreeToFreq(-2.rrand(2), (root+k).midicps, -1);
        bar_tag = \root;
        if (k != 0, {
            bar_tag = \variation;
        });
    });

    if (instrument == \bell, {
        beat_tag = [\offbeat, \variation].choose;
        attention = attention * 0.5.rrand(1.5);
        attributes[\type] = \note;
        attributes.keysValuesChange { |key, value| value * 0.99.rrand(1.01) };
        if (beat_tag == \random, {
            attention = attention * 4;
        });
    });

    if (beat_tag == \basebeat, {
        index = (res*4.rand)/4;
    });

    if (beat_tag == \backbeat, {
        index = (res*2.rand/2) + (res/4);
    });

    if (beat_tag == \offbeat, {
        index = (res*4.rand/4) + (res/8);
    });

    if (beat_tag == \n16th, {
        index = (res*8.rand/8) + (res/16);
    });

    if (beat_tag == \random, {
        index = res.rand;
    });

    if (beat_tag == \variation, {
        index = (res*7.rand/8) + [0, (res/8), (res/16)].choose;
    });

    if (beat_tag == \barline, {
        index = 0;
    });

    // Add bar offset
    if (bar_tag == \whole, {
        index = index + (res*bars.rand);
    });

    if (bar_tag == \root, {
        index = index + (res*(bars-1).rand);
    });

    if (bar_tag == \variation, {
        index = index + (res*(bars-1));
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