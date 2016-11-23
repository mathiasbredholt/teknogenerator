(
var max_attention = 10;
var beat_tags = [\basebeat, \random, \offbeat, \break, \backbeat, \variation, \barline, \silence];
// var harmony_tags = [\root, \variation, \drone];
var harmony_tags = [\drone];

// ~all_instruments = [\bd, \sd, \hat, \ride, \bass, \pad];
~all_instruments = [\bd, \hat, \bass, \pad, \clap, \bell ];

~default_attributes = (
    \bd: (\type: \rest, \sustain_time: 0, \amp: 1, \startFreq: 150, \endFreq: 50, \freqEnvTime: 0.05, \release: 1, \distort: 0),
    \sd: (\type: \rest, \amp: 0.1, \release: 0.02),
    \clap: (\type: \rest, \amp: 1, \release: 0.1, \reverb: 0.1),
    \hat: (\type: \rest, \amp: 0.1, \attack: 1e-3, \release: 0.1, \cutoff: 1000, \reverb: 0.04),
    \ride: (\type: \rest, \release: 1, \amp: 0.5),
    \bass: (\type: \rest, \amp: 0, \freq: 50, \rez: 0, \filter_release: 0.05, \cutoff: 15e3, \t_trig: 0),
    \pad: (\type: \rest, \freq: 440, \amp: 1, \sustaintime: 2, \cutoff: 500, \env_type: 0, \reverb: 0.2),
    \fm_stab: (\type: \rest, \freq: 100, \amp: 0.1, \attack: 0.1, \release: 0.5, \detune: 0.5),
    \bell: (\type: \rest, \freq: 400, \decay: 0.6, \amp: 1)
);

~generate = {
    arg tempo = 127, scale, root = 60;
    var beat_tag;
    var harmony_tag = harmony_tags.choose;
    var attention = 0;
    var instrument = ~all_instruments.choose;
    var attributes = ~default_attributes[instrument];
    var sustained = false;

    if (instrument == \bd, {
        beat_tag = \basebeat;
        attention = 0.1;
        attributes = (\startFreq: 200, \endFreq: 55, \freqEnvTime: 0.08, \amp: 1, \sustain_time: 0.1, \release: 0.2, \type: \note, \distort: 0.6);
    });

    if (instrument == \sd, {
		beat_tag = \backbeat;
        if (beat_tag == \backbeat, {
            attention = 2;
            attributes = (\amp: 0.5, \type: \note, \release: 0.05);
        });
        /*
        if (beat_tag == \random, {
        attributes = (\amp: 0.1, \type: \note, \release: 0.02.rrand(0.1));
        });*/
    });

    if (instrument == \clap, {
		beat_tag = \backbeat;
        if (beat_tag == \backbeat, {
            attention = 2;
            attributes = (\amp: 0.4, \type: \note, \release: 0.05);
        });
        /*
        if (beat_tag == \random, {
        attributes = (\amp: 0.1, \type: \note, \release: 0.02.rrand(0.1));
        });*/
    });

    if (instrument == \hat, {
		beat_tag = [\offbeat, \random].choose;
        if (beat_tag == \offbeat, {
            attention = 1;
            attributes = (\amp: 0.2, \type: \note, \release: 0.05, \cutoff: 10e3);
        });

        /*       if (beat_tag == \variation, {
        attention = 15;
        attributes = (\amp: 0.3, \type: \note, \release: 2, \cutoff: 10e3);
        });
        */
        if (beat_tag == \random, {
            attention = 3;
            attributes = (\amp: 0.1, \type: \note, \release: 0.1, \cutoff: 10e3);
        });

        /*        if (beat_tag == \silence, {
        attention = 1;
        attributes = (\amp: 0, \type: \note, \release: 0.05, \cutoff: 10e3);
        });*/
    });

    if (instrument == \cymbal, {
		beat_tag = \barline
        if (beat_tag == \barline, {
            attention = 15;
            attributes = (\type: \note, \amp: 0.1, \release: 6)
        });
    });

    if (instrument == \ride, {
		beat_tag = \barline
		if (beat_tag == \barline, {
            attention = 9;
            attributes = (\type: \note, \amp: 0.1, \release: 4)
        });
    });

    if (instrument == \bass, {
		beat_tag = [\offbeat, \variation].choose;
		sustained = true;
        if (beat_tag == \offbeat, {
            attention = 3;
            attributes = (
                \type: \note,
                \freq: scale.degreeToFreq(0.rrand(7), 60.midicps, -2),
                \amp: 0.8,
                \filter_release: 0.3,
                \t_trig: 1,
                \rez: 0,
                \cutoff: 300
            );
        });

        if (beat_tag == \variation, {
            attention = 5;
            attributes = (
                \type: \note,
                \freq: scale.degreeToFreq(0.rrand(7), 60.midicps, -2),
                \amp: 0.2,
                \t_trig: 0,
                // \rez: 0.0.rrand(0.6),
                // \cutoff: 500.exprand(10e3)
                \cutoff: 300
            );
        });
    });

    if (instrument == \pad, {
		beat_tag = [\barline, \backbeat].choose;
        if (beat_tag == \barline, {
            if (harmony_tag == \drone, {
                var freqs = { scale.degreeToFreq((0..7).wchoose([ 10, 2, 5, 2, 5, 2, 5, 2 ].normalizeSum), root.midicps, -1) } ! 5;
                var amps = 0.5.exprand(1.0) ! 5;
                attributes = (
                    \type: \note,
                    \freq: freqs,
                    \amp: amps * 0.2,
                    \env_type: 0,
                    \cutoff: 300,
                    \sustaintime: 4*60/tempo,
                    \reverb: 0.5
                );
                attention = 4;
            });
        });
        if (beat_tag == \backbeat, {
            var freqs = { scale.degreeToFreq((0..7).wchoose([ 10, 2, 5, 2, 5, 2, 5, 2 ].normalizeSum), root.midicps, 0) } ! 4;
            var amps = 0.5.exprand(1.0) ! 4;
            attributes = (
                \type: \note,
                \freq: freqs,
                \amp: amps * 0.5,
                \env_type: 1,
                \cutoff: 4e3,
                \sustaintime: 1,
                \reverb: 0.2
            );
            attention = 5;
        });
    });

    if (instrument == \fm_stab, {
		beat_tag = [\basebeat, \random]
        if (beat_tag == \basebeat, {
            attributes = (
                \type: \note,
                \freq: scale.degreeToFreq(0.rrand(7), root.midicps, -2),
                \amp: 0.04,
                \release: 0.05
            );
            attention = 8;
        });

        if (beat_tag == \random, {
            attributes = (
                \type: \note,
                \freq: scale.degreeToFreq(0.rrand(7), root.midicps, -2),
                \amp: 0.005,
                \release: 0.05
            );
            attention = 12;
        });
    });

    if (instrument == \bell, {
		beat_tag = [\offbeat]
        if (beat_tag == \offbeat, {
            attributes = (
                \type: \note,
                \amp: 0.06
            );
            attention = 8;
        });
    });

    (\instrument: instrument, \beat_tag: beat_tag, \sustained: sustained, \attention: attention, \attributes: attributes)
};
)
