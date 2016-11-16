(
var max_attention = 10;
var beat_tags = [\basebeat, \random, \offbeat, \break, \backbeat, \variation, \barline];
// var harmony_tags = [\root, \variation, \drone];
var harmony_tags = [\drone];

// ~all_instruments = [\bd, \sd, \hat, \ride, \bass, \pad];
~all_instruments = [\bd, \hat, \ride, \bass, \pad, \clap];

~default_attributes = (
    \bd: (\type: \rest, \amp: 0.1, \startFreq: 150, \endFreq: 50, \freqEnvTime: 0.05, \release: 0.1),
    \sd: (\type: \rest, \amp: 0.1, \release: 0.02),
    \clap: (\type: \rest, \amp: 1, \release: 0.1),
    \hat: (\type: \rest, \amp: 0.1, \attack: 1e-3, \release: 0.1, \cutoff: 1000),
    \ride: (\type: \rest, \release: 1, \amp: 0.5),
    \bass: (\type: \rest, \amp: 0, \freq: 50, \rez: 0, \filter_release: 0.05, \cutoff: 15e3, \t_trig: 1),
    \pad: (\type: \rest, \freq: 440, \amp: 1, \sustaintime: 2, \cutoff: 500, \env_type: 0)
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
            attributes = (\startFreq: 150, \endFreq: 50, \freqEnvTime: 0.1, \amp: 0.8, \release: 0.4, \type: \note);
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
            attributes = (\amp: 1, \type: \note, \release: 0.1.rrand(0.35));
        });
        /*
        if (beat_tag == \random, {
        attributes = (\amp: 0.1, \type: \note, \release: 0.02.rrand(0.1));
        });*/
    });

    if (instrument == \hat, {
        if (beat_tag == \offbeat, {
            attention = 1;
            attributes = (\amp: 0.6, \type: \note, \release: 0.03, \cutoff: 10e3);
        });

        if (beat_tag == \random, {
            attention = 1;
            attributes = (\amp: 0.3, \type: \note, \release: 0.02, \cutoff: 10e3);
        });
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
        if (beat_tag == \offbeat, {
            attention = 4;
            attributes = (
                \type: \note,
                \freq: Scale.minor.degreeToFreq(-5.rrand(5), 60.midicps, -2),
                \amp: 1,
                \filter_release: 0.03.rrand(0.2),
                \t_trig: 1,
                \rez: 0.0.rrand(0.9),
                \cutoff: 15e3
            );
        });

        if (beat_tag == \random, {
            attention = 4;
            attributes = (
                \type: \note,
                \freq: Scale.minor.degreeToFreq(-5.rrand(5), 60.midicps, -2),
                \amp: 0.5,
                \filter_release: 0.03.rrand(0.2),
                \t_trig: 1,
                \rez: 0.0.rrand(0.9),
                \cutoff: 15e3
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
                    \amp: amps * 0.5,
                    \env_type: 0,
                    \cutoff: 1e3.rrand(2e3),
                    \sustaintime: 4*60/tempo
                );
                attention = 2;
            });
        });
        if (beat_tag == \random, {
            var freqs = { scale.degreeToFreq((0..7).wchoose([ 10, 2, 5, 2, 5, 2, 5, 2 ].normalizeSum), 60.midicps, 0) } ! 4;
            var amps = 0.5.exprand(1.0) ! 4;
            attributes = (
                \type: \note,
                \freq: freqs,
                \amp: amps * 2,
                \env_type: 1,
                \cutoff: 1e3.rrand(10e3),
                \sustaintime: 1
            );
            attention = 2;
        });
    });

    (\instrument: instrument, \beat_tag: beat_tag, \sustained: sustained, \attention: attention, \attributes: attributes)
};
)
