(
var max_attention = 5;
var all_tags = [\basebeat, \random, \offbeat, \drone, \root, \harmonic_variation, \break, \backbeat, \rhythmic_variation];

~all_instruments = [\bd, \sd];

~default_attributes = (\type: \rest, \amp: 0, \startFreq: 0, \release: 0, \freqEnvTime: 0, \endFreq: 0);

~generate = {
    var tags = [ all_tags.choose ];
    var attention = max_attention.rand;
    var instrument = ~all_instruments.choose;
    var attributes = ~default_attributes;

    if (instrument == \bd, {
        if (tags.find([\basebeat]) != nil, {
            attributes = (\startFreq: 150, \endFreq: 50, \freqEnvTime: 0.05, \amp: 0.8, \release: 0.4, \type: \note);
        });
    });

    if (instrument == \sd, {
        if (tags.find([\backbeat]) != nil, {
            attributes = (\amp: 0.3, \type: \note, \release: 0.05.rrand(0.1));
        });
    });

    (\instrument: instrument, \tags: tags, \sustained: false, \attention: attention, \attributes: attributes)
};
)