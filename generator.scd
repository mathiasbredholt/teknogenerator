(
var max_attention = 5;
var all_tags = [\basebeat, \random, \offbeat, \drone, \root, \harmonic_variation, \break, \backbeat, \rhythmic_variation];

~all_instruments = [\bd, \sd, \hat];

~default_attributes = (\type: \rest, \amp: 0, \startFreq: 0, \release: 0, \freqEnvTime: 0, \endFreq: 0, \freq: 0);

~generate = {
    var tags = [ all_tags.choose ];
    var attention = max_attention.rand;
    var instrument = ~all_instruments.choose;
    var attributes = ~default_attributes;

    if (instrument == \bd, {
        if (tags.find([\basebeat]) != nil, {
            attributes = (\startFreq: 150.rrand(250), \endFreq: 50, \freqEnvTime: 0.2, \amp: 0.8, \release: 0.4, \type: \note);
        });
    });

    if (instrument == \sd, {
        if (tags.find([\backbeat]) != nil, {
            attributes = (\amp: 0.3, \type: \note, \release: 0.05.rrand(0.5));
        });

        if (tags.find([\random]) != nil, {
            attributes = (\amp: 0.2, \type: \note, \release: 0.01.rrand(0.2));
        });
    });

    if (instrument == \hat, {
        if (tags.find([\offbeat]) != nil, {
            attributes = (\amp: 0.3, \type: \note, \release: 0.2, \freq: 2000);
        });

        if (tags.find([\random]) != nil, {
            attributes = (\amp: 0.1, \type: \note, \release: 0.1, \freq: 8000);
        });
    });

    (\instrument: instrument, \tags: tags, \sustained: false, \attention: attention, \attributes: attributes)
};
)
