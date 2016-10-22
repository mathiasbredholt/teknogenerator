/*
|--------------------------------------------|
| TEKNO GENERATOR 3000                       |
|--------------------------------------------|
| By Mathias Bredholt and Mathias Kirkegaard |
| Copyright 2016 - All rights reserved.      |
|                                            |
| Run instruments.scd then generator.scd     |
| and then this.                             |
|--------------------------------------------|
*/

(
var res = 16;
var num_grains = 256;
var seq_duration = 4;

// (\bd: (\amp: [1, 0, 1, 0, 1, 0, 1 ..], \type: [rest, note, rest, note ...]))
// 1, 0, 1, 0, 1, 0, 1 ..
// rest, note, rest, note ...

//(\instrument: \bd, \tags: [\basebeat], \sustained: false, \attention: 2, \attributes: (\amp: 0.1))

Tempo.bpm = 127;

~all_instruments.do {
    arg instr;
    Pdef((instr ++ "_pat").asSymbol).play;
};

{
    loop {
        // Generate array of random grains
        var seq = ();
        var grains = { ~generate.value } ! num_grains;

        // ----- Fill sequence with silence -------
        ~all_instruments.do {
            arg instr;
            // Add all instruments to sequence
            seq.add(instr -> ());
            // Iterate through attributes
            ~default_attributes.keysValuesDo {
                arg key, value;
                // For each attribute add a list of repeated default values
                seq[instr].add(key -> (value ! res));
            }
        };
        // ----------------------------------------

        // Iterate through grain array
        grains.size.do {
            arg i;
            var index = 0;

            if (grains[i][\tags].find([\basebeat]) != nil, {
                index = (res/4) * 4.rand;

                // index.postln;
                if (seq[grains[i][\instrument]][\type][index] == \rest, {
                    grains[i][\attributes].keysValuesDo {
                        arg key, value;
                        seq[grains[i][\instrument]][key][index] = value;
                    }
                });
            });

            if (grains[i][\tags].find([\backbeat]) != nil, {
                index = ((res/2).asInt * 2.rand + (res/4));
                if (seq[grains[i][\instrument]][\type][index] == \rest, {
                    grains[i][\attributes].keysValuesDo {
                        arg key, value;
                        seq[grains[i][\instrument]][key][index] = value;
                    }
                });
            });

            if (grains[i][\tags].find([\offbeat]) != nil, {
                index = ((res/4).asInt * 4.rand + (res/8));
                if (seq[grains[i][\instrument]][\type][index] == \rest, {
                    grains[i][\attributes].keysValuesDo {
                        arg key, value;
                        seq[grains[i][\instrument]][key][index] = value;
                    }
                });
            });

            if (grains[i][\tags].find([\random]) != nil, {
                index = res.rand;
                if (seq[grains[i][\instrument]][\type][index] == \rest, {
                    grains[i][\attributes].keysValuesDo {
                        arg key, value;
                        seq[grains[i][\instrument]][key][index] = value;
                    }
                });
            });
        };

        // Iterate through all instruments in sequence
        seq.keysValuesDo {
            arg key, attributes;
            var pattern = ();

            // For each instrument attribute at a Pseq containing the sequence of values
            attributes.keysValuesDo {
                arg key, value;
                pattern.add(key->Pseq(value, inf))
            };

            // Chain the sequences with a pattern containing the instrument
            Pdef((key ++ "_pat").asSymbol, Pchain(Pbind(
                \instrument, key,
                \dur, seq_duration/res,
            ), Pbind(*pattern.asPairs)));
        };

        (seq_duration * 4).wait;

    }
}.fork;
)