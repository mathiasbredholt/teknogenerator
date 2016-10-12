(
var max_attention = 5;
var all_tags = [\basebeat, \random, \silence, \offbeat, \drone, \root, \harmonic_variation, \break, \backbeat, \rhythmic_variation];
var all_instruments = [\bd, \sd];

~generate = {
    var tags = { all_tags.choose } ! 1.rrand(3);
    var attention = max_attention.rand;
    var instrument = all_instruments.choose;
    var attributes = (\type: \rest, \amp: 0, \startFreq: 0, \release: 0, \freqEnvTime: 0, \endFreq: 0);

    if (instrument == \bd, {
        if (tags.find([\basebeat]) != nil, {
            attributes = (\startFreq: 400.rrand(5000), \endFreq: 50.rrand(500), \freqEnvtime: 0.05.rrand(0.1), \amp: 0.5, \release: 1, \type: \note);
        });
    });

    if (instrument == \sd, {
        if (tags.find([\backbeat]) != nil, {
            attributes = (\amp: 0.5, \type: \note, \release: 0.02.rrand(0.3));
        });
    });

    (\instrument: instrument, \tags: tags, \sustained: false, \attention: attention, \attributes: attributes)
};
)