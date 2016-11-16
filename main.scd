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
var res = 32;
var num_grains = 500;
var seq_duration = 4;
var max_attention = 50;

// translates from
//(\instrument: \bd, \beat_tag: \basebeat, \sustained: false, \attention: 2, \attributes: (\amp: 0.1))
// to
// (\bd: (\sustained: false, \seq: (\amp: [1, 0, 1, 0, 1, 0, 1 ..], \type: [rest, note, rest, note ...])))
// 1, 0, 1, 0, 1, 0, 1 ..
// rest, note, rest, note ...

Tempo.bpm = 127;

~all_instruments.do {
    arg instr;
    Pdef((instr ++ "_pat").asSymbol).play;
};

g = Group.new(s);

fork {
    loop {
        var scale, seq, grains, attention_array;
        thisThread.randSeed = 4;

        scale = [ Scale.minor, Scale.dorian, Scale.lydian, Scale.mixolydian, Scale.major ].choose;

        seq = ();
        // Generate array of random grains
        grains = { ~generate.value(Tempo.bpm, scale) } ! num_grains;
        attention_array = [];


        // ----- Fill sequence with silence -------
        ~all_instruments.do {
            arg instr;
            // Add all instruments to sequence
            seq.add(instr -> ());
            seq[instr].add(\sustained -> false);
            seq[instr].add(\seq -> ());
            // Iterate through attributes
            ~default_attributes[instr].keysValuesDo {
                arg key, value;
                // For each attribute add a list of repeated default values
                seq[instr][\seq].add(key -> (value ! res));
            }
        };
        // ----------------------------------------

        // Iterate through grain array
        grains.do {
            arg grain;
            var index = 0;

            if (grain[\beat_tag] == \basebeat, {
                index = (res/4) * 4.rand;
            });

            if (grain[\beat_tag] == \backbeat, {
                index = ((res/2).asInt * 2.rand + (res/4));
            });

            if (grain[\beat_tag] == \offbeat, {
                index = ((res/4).asInt * 4.rand + (res/8));
            });
/*
            if (grain[\beat_tag] == \silence, {
                index = ((res/4).asInt * 4.rand + (res/8));
            });*/

            if (grain[\beat_tag] == \random, {
                index = res.rand;
            });

            if (grain[\beat_tag] == \variation, {
                index = ((res/4).asInt * 4.rand + ((res/4).rand));
            });

            if (grain[\beat_tag] == \barline, {
                index = 0;
            });

            if (grain[\beat_tag] == \rhythmic_variation, {
                index = 0;
            });

            // If there is no audible grain already at the chosen position
            // and the total attention is less than max attention
            if (
                (seq[grain[\instrument]][\seq][\type][index] == \rest) &&
                ((attention_array ++ [grain[\attention]]).mean < 0.5), {
                    // Change the attributes of the grain to non-silent
                    grain[\attributes].keysValuesDo {
                        arg key, value;
                        seq[grain[\instrument]][\seq][key][index] = value;
                    };

                    // if (grain[\attention] > 0, {
                        attention_array = attention_array ++ [grain[\attention]];
            // });
            });

            seq[grain[\instrument]][\sustained] = grain[\sustained]
        };

        // Iterate through all instruments in sequence
        seq.keysValuesDo {
            // key is instrument, attributes is (sustained, seq)
            arg key, attributes;
            var pattern = ();

            // For each instrument attribute at a Pseq containing the sequence of values
            attributes[\seq].keysValuesDo {
                arg key, value;
                pattern.add(key->Pseq(value, inf));
            };

            // Chain the sequences with a pattern containing the instrument
            if (attributes[\sustained], {
                Pdef((key ++ "_pat").asSymbol, Pchain(Pmono(
                    key,
                    \group, g,
                    \dur, seq_duration/res,
                ), Pbind(*pattern.asPairs)));
            }, {
                Pdef((key ++ "_pat").asSymbol, Pchain(Pbind(
                    \instrument, key,
                    \group, g,
                    \dur, seq_duration/res,
                ), Pbind(*pattern.asPairs)));
            });
        };

        (seq_duration * 4).wait;

    }
};

{
    var master_in = In.ar(0, 2);
    var reverb_in = In.ar(~reverb, 2);

    var reverb = GVerb.ar(reverb_in, 100, 5, drylevel: 0);

    var mix = Mix([ master_in, reverb ]) * 0.5;
    var compressor = Compander.ar(mix, mix * 2, 0.2, 1, 1/4);
    var master_out =  compressor;

    ReplaceOut.ar(0, master_out);
}.play(g, addAction: \addToTail);
)