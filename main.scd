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
var num_grains = 256;
var seq_duration = 4;
var seed = (2**15).rand.round;

var root, scale, grains, state_rand;
// seed:  410

/*
STATES:
0 - Minimal
1 - Build-up
2 - Break
3 - Climax
4 - Outro
*/

~bass_gate.set(0);
Synth(\bass_real);


thisThread.randSeed = seed;
("seed: " + seed).postln;


~create_song = {
    var bars = 2;
    state_rand = { 5.rand } ! 256;

    // Generate array of random grains
    root = 55.rrand(66);
    scale = [ Scale.majorPentatonic, Scale.minorPentatonic, Scale.dorian, Scale.lydian ].choose;
    // scale = [ Scale.chromatic24 ].choose;
    ~init_generation.value;
    grains = { ~generate.value(Tempo.bpm, scale, root, res, bars) } ! num_grains;

    // translates from
    //(\instrument: \bd, \beat_tag: \basebeat, \sustained: false, \attention: 2, \attributes: (\amp: 0.1))
    // to
    // (\bd: (\sustained: false, \seq: (\amp: [1, 0, 1, 0, 1, 0, 1 ..], \type: [rest, note, rest, note ...])))
    // 1, 0, 1, 0, 1, 0, 1 ..
    // rest, note, rest, note ...

    Tempo.bpm = 135;

    ~all_instruments.do {
        arg instr;
        Pdef((instr ++ "_pat").asSymbol).play;
    };

    g = Group.new(s);


    fork {
        var is_playing = true;
        var bar_count = 0;
        var state = 0;
        var state_count = 0;
        var attention_mean = 0;
        var attention_mean_calc = [ 1.0.rrand(1.5),  1.7.rrand(2.0), 0.9, 2.2.rrand(3.0), 0.0];

        // ("The time is "++Date.getDate.format("%H:%M") ++ " and you're listening to Techno Generator 3000").speak;


        while({ is_playing }, {
            var seq, attention_array, tmp, deviation = 0.5, mu = 0, dev = 0, median, swing = 0.0.rrand(0.5);

            if (bar_count == 0, {
                ("Progress: "++state_count).postln;
                if (state_count < 10, {
                    state_count = state_count + 1
                }, {
                    is_playing = false;
                });

                attention_mean = attention_mean_calc[state];

                ("State: "++state).postln;
                switch(state,
                    0, {
                        state = [ 0, 1 ].choose;
                    },
                    1, {
                        state = [ 1, 0, 2, 3 ].choose;
                    },
                    2, {
                        state = [ 2, 3, 0 ].choose;
                        deviation = 0.2;
                    },
                    3, {
                        state = [ 3, 0 ].choose;
                    }
                );
            });

            // Creates the 4-bar feelin'
            if(bar_count > 2, {
                attention_mean = attention_mean * [ 1.25, 0.75 ].choose;
            });

            swing = 0;

            seq = ();
            attention_array = [-1];


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
                    seq[instr][\seq].add(key -> (value ! (res * bars)));
                }
            };

            // ----------------------------------------

            // Iterate through grain array
            grains.do {
                arg grain;

                // Mean and standeard deviation of attention array
                tmp = attention_array ++ [grain[\attention]];
                mu = tmp.mean;
                median = tmp[(tmp.size/2).asInt];
                dev = ((tmp - mu)**2).sum/(tmp.size);
                // If there is no audible grain already at the chosen position
                // and the grain doesn't violate attention attention parameters

                if (
                    //(seq[grain[\instrument]][\seq][\type][index] == \rest) &&
                    (mu < attention_mean) && (dev > deviation), {
                        // Change the attributes of the grain to non-silent
                        grain[\attributes].keysValuesDo {
                            arg key, value;
                            seq[grain[\instrument]][\seq][key][grain[\index]] = value;
                        };

                        attention_array = attention_array ++ [grain[\attention]];
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
                /*            if (attributes[\sustained], {
                Pdef((key ++ "_pat").asSymbol, Pchain(Pmono(
                key,
                \group, g,
                \dur, seq_duration/res,
                ), Pbind(*pattern.asPairs)));
                }, {*/
                Pdef((key ++ "_pat").asSymbol, Pchain(~swingify, Pbind(
                    \instrument, key,
                    \group, g,
                    \dur, seq_duration/res,
                ), Pbind(*pattern.asPairs), (swingBase: 0.5, swingAmount: swing, swingThreshold: 0.1)));
                // });
            };
            (seq_duration*bars).wait;
            bar_count = (bar_count + 1) % 4;
        });

        ~create_song.value;
    };
};

~create_song.value;

{
    var master_in = In.ar(0, 2);
    var delay_in = In.ar(~delay, 2);
    var reverb_in = In.ar(~reverb, 2);

    var reverb = GVerb.ar(reverb_in[0], 10.rrand(150), 0.5.rrand(4.0), 0.2, 0.5, 30, drylevel: 0, earlyreflevel: 1, taillevel: 1);
    var delay = CombC.ar(delay_in, 60/Tempo.bpm * 5/3, 60/Tempo.bpm * 5/3, 5);

    var mix = master_in + delay + Compander.ar(reverb, In.ar(~sidechain) * 4, 0.1, 1, 1/4, 0.05, 0.2);
    var compressor = Compander.ar(mix, mix, 0.08, 1, 1/3, 0.02, 0.05) * 0.7;
    var master_out =  Limiter.ar(compressor, 0.97, 0.02);

    ReplaceOut.ar(0, master_out);

}.play(g, addAction: \addToTail);
)
2**63