(
var max_attention = 10;
var beat_tags = [\basebeat, \random, \offbeat, \break, \backbeat, \variation, \barline, \silence];
// var harmony_tags = [\root, \variation, \drone];
var harmony_tags = [\drone];

// ~all_instruments = [\bd, \sd, \hat, \ride, \bass, \pad];
~all_instruments = [\bd, \hat, \ride, \bass, \pad, \clap, \fm_stab];

~default_attributes = (
    \bd: (\type: \rest, \sustain_time: 0, \amp: 1, \startFreq: 150, \endFreq: 50, \freqEnvTime: 0.05, \release: 0.1, \distort: 0),
    \sd: (\type: \rest, \amp: 0.1, \release: 0.02),
    \clap: (\type: \rest, \amp: 1, \release: 0.1),
    \hat: (\type: \rest, \amp: 0.1, \attack: 1e-3, \release: 0.1, \cutoff: 1000),
    \ride: (\type: \rest, \release: 1, \amp: 0.5),
    \bass: (\type: \rest, \amp: 0, \freq: 50, \rez: 0, \filter_release: 0.05, \cutoff: 15e3, \t_trig: 1),
    \pad: (\type: \rest, \freq: 440, \amp: 1, \sustaintime: 2, \cutoff: 500, \env_type: 0, \reverb: 0.2),
    \fm_stab: (\type: \rest, \freq: 100, \amp: 0.1, \attack: 0.1, \release: 0.5, \detune: 0.5)
);

~generate = {
    arg tempo = 127, scale;
    var beat_tag = beat_tags.choose;
    var harmony_tag = harmony_tags.choose;
    var attention = 0;
    var instrument = ~all_instruments.choose;
    var attributes = ~default_attributes[instrument];
    var sustained = false;

    if (instrument == \bd, {
        if (beat_tag == \basebeat, {
            attention = 2;
            attributes = (\startFreq: 200, \endFreq: 50, \freqEnvTime: 0.08, \amp: 0.2, \sustain_time: 0.1, \release: 0.4, \type: \note, \distort: 0.0.rrand(0.6));
        });
    });

    if (instrument == \sd, {
        if (beat_tag == \backbeat, {
            attention = 2;
            attributes = (\amp: 0.3, \type: \note, \release: 0.03.rrand(0.2));
        });
        /*
        if (beat_tag == \random, {
        attributes = (\amp: 0.1, \type: \note, \release: 0.02.rrand(0.1));
        });*/
    });

    if (instrument == \clap, {
        if (beat_tag == \backbeat, {
            attention = 2;
            attributes = (\amp: 0.5, \type: \note, \release: 0.1);
        });
        /*
        if (beat_tag == \random, {
        attributes = (\amp: 0.1, \type: \note, \release: 0.02.rrand(0.1));
        });*/
    });

    if (instrument == \hat, {
        if (beat_tag == \offbeat, {
            attention = 1;
            attributes = (\amp: 0.6, \type: \note, \release: 0.03, \cutoff: 6e3);
        });

        if (beat_tag == \variation, {
            attention = 15;
            attributes = (\amp: 0.1, \type: \note, \release: 2, \cutoff: 10e3);
        });

        if (beat_tag == \random, {
            attention = 10;
            attributes = (\amp: 0.3, \type: \note, \release: 0.05, \cutoff: 10e3);
        });

        /*        if (beat_tag == \silence, {
        attention = 1;
        attributes = (\amp: 0, \type: \note, \release: 0.05, \cutoff: 10e3);
        });*/
    });

    if (instrument == \cymbal, {
        if (beat_tag == \rhythmic_variation, {
            attention = 10;
            attributes = (\type: \note, \amp: 1, \release: 6)
        });
    });

    if (instrument == \ride, {
        if (beat_tag == \rhythmic_variation, {
            attention = 8;
            attributes = (\type: \note, \amp: 2, \release: 1)
        });
    });

    if (instrument == \bass, {
        sustained = false;
        if ((beat_tag == \offbeat) || (beat_tag == \backbeat), {
            attention = 4;
            attributes = (
                \type: \note,
                \freq: Scale.minor.degreeToFreq(-3.rrand(7), 60.midicps, -2),
                \amp: 1,
                \filter_release: 0.02.rrand(0.1),
                \t_trig: 1,
                \rez: 0.0.rrand(0.2),
                \cutoff: 5e3
            );
        });

        if (beat_tag == \variation, {
            attention = 15;
            attributes = (
                \type: \note,
                \freq: Scale.minor.degreeToFreq(-3.rrand(7), 60.midicps, -2),
                \amp: 0.5,
                \filter_release: 0.02.rrand(0.1),
                \t_trig: 0,
                \rez: 0.0.rrand(0.2),
                \cutoff: 5e3
            );
        });
    });

    if (instrument == \pad, {
        if (beat_tag == \barline, {
            if (harmony_tag == \drone, {
                var freqs = { scale.degreeToFreq((0..7).wchoose([ 10, 2, 5, 2, 5, 2, 5, 2 ].normalizeSum), 60.midicps, 0) } ! 5;
                var amps = 0.5.exprand(1.0) ! 5;
                attributes = (
                    \type: \note,
                    \freq: freqs,
                    \amp: amps * 0.2,
                    \env_type: 0,
                    \cutoff: 1e3.rrand(10e3),
                    \sustaintime: 4*60/tempo,
                    \reverb: 0.3
                );
                attention = 2;
            });
        });
        if (beat_tag == \variation, {
            var freqs = { scale.degreeToFreq((0..7).wchoose([ 10, 2, 5, 2, 5, 2, 5, 2 ].normalizeSum), 60.midicps, 0) } ! 4;
            var amps = 0.5.exprand(1.0) ! 4;
            attributes = (
                \type: \note,
                \freq: freqs,
                \amp: amps * 1.5,
                \env_type: 1,
                \cutoff: 1e3.rrand(10e3),
                \sustaintime: 1,
                \reverb: 0
            );
            attention = 10;
        });
    });

    if (instrument == \fm_stab, {
        if (beat_tag == \basebeat, {
            attributes = (
                \type: \note,
                \freq: scale.degreeToFreq(0.rrand(7), 60.midicps, -2),
                \amp: 0.2,
                \release: 0.1
            );
            attention = 15;
        });

        if (beat_tag == \random, {
            attributes = (
                \type: \note,
                \freq: scale.degreeToFreq(0.rrand(7), 60.midicps, -2),
                \amp: 0.005,
                \release: 0.1
            );
            attention = 10;
        });
    });

    (\instrument: instrument, \beat_tag: beat_tag, \sustained: sustained, \attention: attention, \attributes: attributes)
};
)
