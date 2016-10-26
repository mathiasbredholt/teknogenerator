(
var max_attention = 10;
var all_tags = [\basebeat, \random, \offbeat, \drone, \root, \harmonic_variation, \break, \backbeat, \rhythmic_variation];

~all_instruments = [\bd, \sd, \hat, \cymbal, \ride];

~default_attributes = (\type: \rest, \amp: 0, \startFreq: 0, \release: 0, \freqEnvTime: 0, \endFreq: 0, \freq: 0);

~generate = {
    var tags = [ all_tags.choose ];
    var attention = 0;
    var instrument = ~all_instruments.choose;
    var attributes = ~default_attributes;

    if (instrument == \bd, {
        if (tags.find([\basebeat]) != nil, {
            attention = 3;
            attributes = (\startFreq: 150.rrand(250), \endFreq: 50, \freqEnvTime: 0.2, \amp: 0.8, \release: 0.4, \type: \note);
        });
    });

    if (instrument == \sd, {
        if (tags.find([\backbeat]) != nil, {
            attention = 3;
            attributes = (\amp: 0.3, \type: \note, \release: 0.05.rrand(0.5));
        });

        if (tags.find([\random]) != nil, {
            attributes = (\amp: 0.2, \type: \note, \release: 0.05.rrand(0.2));
        });
    });

    if (instrument == \hat, {
        if (tags.find([\offbeat]) != nil, {
            attention = 2;
            attributes = (\amp: 0.3, \type: \note, \release: 0.1, \freq: 4000);
        });

        if (tags.find([\random]) != nil, {
            attention = 1;
            attributes = (\amp: 0.05, \type: \note, \release: 0.1, \freq: 8000);
        });
    });

    if (instrument == \cymbal, {
        if (tags.find([\rhythmic_variation]) != nil, {
            attention = 10;
            attributes = (\type: \note, \amp: 1, \release: 6)
        });
    });

    if (instrument == \ride, {
        if (tags.find([\rhythmic_variation]) != nil, {
            attention = 8;
            attributes = (\type: \note, \amp: 2, \release: 1)
        });
    });

    (\instrument: instrument, \tags: tags, \sustained: false, \attention: attention, \attributes: attributes)
};
)
