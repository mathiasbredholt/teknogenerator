(
var max_attention = 10;
var beat_tags = [\basebeat, \random, \offbeat, \break, \backbeat, \variation, \barline ];
// var harmony_tags = [\root, \variation, \drone];
var harmony_tags = [\drone, \root];

~all_instruments = [\bd, \clap, \hat, \bass, \pad, \bell, \fm_stab, \cymbal, \ride ];
// ~all_instruments= [\bass];

~init_generation = {
    ~default_attributes = (
        \bd: (\type: \rest, \sustain_time: 0.1.rrand(0.4), \amp: 1, \freq: 50.0.rrand(65.0), \release: 1.5.rrand(2.0), \distort: 0.0.rrand(0.6)),
        \sd: (\type: \rest, \amp: 0.4, \release: 0.02.rrand(0.2), \reverb: 0.001.exprand(0.05)),
        \clap: (\type: \rest, \amp: 0.7, \release: 0.05.exprand(0.15), \reverb: 0.1, \lfo: 10.0.rrand(60), \cutoff: 500.0.exprand(10e3)),
        \hat: (\type: \rest, \amp: 0.5, \attack: 1e-3, \release: 0.02.rrand(0.05), \cutoff: 5e3.rrand(15e3), \reverrandrb: 0.04),
        \ride: (\type: \rest, \release: 2.0.rrand(5), \amp: 0.1),
        \cymbal: (\type: \rest, \release: 2.0.rrand(8.0), \amp: 0.1, \reverb: 0.001.exprand(0.05)),
        \bass: (\type: \rest, \amp: 1, \freq: 50, \rez: 0.0.rrand(0.4), \filter_release: 0.01.exprand(1.0), \cutoff: 500.rrand(5e3), \sustain_time: 0.5, \legato: 4),
        \pad: (\type: \rest, \freq: 440, \amp: 1, \sustain_time: 2, \cutoff: 1e3.rrand(15e3), \env_type: 0, \reverb: 0.2),
        \fm_stab: (\type: \rest, \freq: 100, \amp: 0.1, \attack: 0.1, \release: 0.5, \detune: 0.5),
        \bell: (\type: \rest, \freq: 200.0.exprand(1200.0), \decay: 0.1.rrand(0.9), \amp: 0.1, \reverb: 0.0.rrand(0.1))
    );

    ~default_attention = (
        \bd: 0,
        \sd: 4,
        \clap: 2,
        \hat: 1,
        \ride: 10,
        \cymbal: 10,
        \bass: 5,
        \pad: 10,
        \fm_stab: 10,
        \bell: 5
    );
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
        beat_tag = \basebeat;
        // attention = 0.0.rrand(1.0);
        attributes[\type] = \note;
        // attributes.keysValuesChange { |key, value| value * 0.99.rrand(1.01) };
        attributes[\amp] = 1
        // attributes.postln;
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
        attributes[\amp] = 0.3;
    });

    if (instrument == \hat, {
        beat_tag = [\offbeat, \random].choose;
        attention = attention * 0.5.rrand(1.5);
        attributes[\type] = \note;
        attributes.keysValuesChange { |key, value| value * 0.5.rrand(1.5) };
        attributes[\release] = attributes[\release] * 0.5.exprand(20);
        if (beat_tag == \random, {
            attention = 7;
        });
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

    if (instrument == \bass, {
        beat_tag = [\variation, \offbeat].choose;
        attributes[\type] = \note;
        attention = attention * 0.5.rrand(1.5);
        attributes.keysValuesChange { |key, value| value * 0.5.rrand(1.5) };
        attributes[\freq] = scale.degreeToFreq(0.rrand(5), root.midicps, -2);
        attributes[\sustain_time] = [ 2 ].choose*60/tempo;
        attributes[\legato] = [4, 16, 32, 64].wchoose([0.1, 0.2, 0.4, 0.3]);
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
            attributes[\amp] = 0.08;
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
        attention = attention * 0.5.rrand(1.5);
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
)
