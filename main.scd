(
// Example of sound grain
(\instrument: \bd, \tags: [\basebeat], \sustained: false, \attention: 2, \attributes: (\amp: 0.1))
)


(
var grains = { ~generate.value } ! 64;

grains.do {
    arg i;

};


)

(
var grains = { ~generate.value } ! 128;
var seq = ();

// (\bd: (\amp: [1, 0, 1, 0, 1, 0, 1 ..], \type: [rest, note, rest, note ...]))
// 1, 0, 1, 0, 1, 0, 1 ..
// rest, note, rest, note ...

//(\instrument: \bd, \tags: [\basebeat], \sustained: false, \attention: 2, \attributes: (\amp: 0.1))


grains.size.do {
    arg i;

    if (seq.at(grains[i][\instrument]) == nil, {
        seq.add(grains[i][\instrument] -> ());
        grains[i][\attributes].keysDo {
            arg key;
            seq[grains[i][\instrument]].add(key -> List())
        }
    });

    if (seq.at(grains[i][\instrument]) != nil, {
        grains[i][\attributes].keysValuesDo {
            arg key, value;
            seq[grains[i][\instrument]][key].add(value);
        }
    });
};

seq.keysValuesDo {
    arg key, attributes;
    var pattern = ();

    attributes.keysValuesDo {
        arg key, value;
        pattern.add(key->Pseq(value.array, inf))
    };

    Pchain(Pbind(
        \instrument, key,
        \dur, 1/16,
    ), Pbind(*pattern.asPairs)).play
};

)


Dictionary