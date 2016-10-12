(
var max_attention = 5;
var all_tags = [\basebeat, \random, \silence, \offbeat, \drone, \root, \harmonic_variation, \break, \backbeat, \rhythmic_variation];
var all_instruments = [\bd];

~generate = {
    var tags = { all_tags.choose } ! 1.rrand(3);
    var attention = max_attention.rand;
    var instrument = all_instruments.choose;
    var attributes = (\type: \rest);

    if (instrument == \bd, {
        if (tags.find([\basebeat]) != nil, {
            attributes = (\amp: 0.1, \type: \note);
        });
    });

    (\instrument: instrument, \tags: tags, \sustained: false, \attention: attention, \attributes: attributes)
};
)