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
var max_attention = 30;

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
        var seq = ();
        // Generate array of random grains
        var grains = { ~generate.value } ! num_grains;
        var attention_array = [];

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
        grains.do {
            arg grain;
            var index = 0;

            if (grain[\tags].find([\basebeat]) != nil, {
                index = (res/4) * 4.rand;
            });

            if (grain[\tags].find([\backbeat]) != nil, {
                index = ((res/2).asInt * 2.rand + (res/4));
            });

            if (grain[\tags].find([\offbeat]) != nil, {
                index = ((res/4).asInt * 4.rand + (res/8));
            });

            if (grain[\tags].find([\random]) != nil, {
                index = res.rand;
            });

            if (grain[\tags].find([\rhythmic_variation]) != nil, {
                index = res.rand;
            });

            // If there is no audible grain already at the chosen position
            // and the total attention is less than max attention
            if (
                (seq[grain[\instrument]][\type][index] == \rest) &&
                ((attention_array ++ [grain[\attention]]).mean < 3), {
                    // Change the attributes of the grain to non-silent
                    grain[\attributes].keysValuesDo {
                        arg key, value;
                        seq[grain[\instrument]][key][index] = value;
                    };

                    if (grain[\attention] > 0, {
                        attention_array = attention_array ++ [grain[\attention]];
                        attention_array.postln;
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