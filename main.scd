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
var num_grains = 512;
var seq_duration = 4;
var seed = (2**15).rand.round;

var root, scale, grains, state_rand;

/*
STATES:
0 - Minimal
1 - Build-up
2 - Break
3 - Climax
*/
thisThread.randSeed = seed;
//6508 - 85 BPM
// 28654 - 85 BPM

~bass_p.set(0 ! 8);
Synth(\bass_real);
~sweep_control = Synth(\sweep_control);




("seed: " + seed).postln;


~create_song = {
    var bars = [1, 2, 3, 4].choose;
    state_rand = { 5.rand } ! 256;

    // Generate array of random grains
    root = 55.rrand(66);
    scale = [ Scale.majorPentatonic, Scale.minorPentatonic, Scale.dorian, Scale.lydian, Scale.chromatic24, Scale.hexAeolian ].choose;
    ~init_generation.value;
    grains = { ~generate.value(Tempo.bpm, scale, root, res, bars) } ! num_grains;

    // translates from
    //(\instrument: \bd, \beat_tag: \basebeat, \sustained: false, \attention: 2, \attributes: (\amp: 0.1))
    // to
    // (\bd: (\sustained: false, \seq: (\amp: [1, 0, 1, 0, 1, 0, 1 ..], \type: [rest, note, rest, note ...])))
    // 1, 0, 1, 0, 1, 0, 1 ..
    // rest, note, rest, note ...

    Tempo.bpm = 127;



    ~all_instruments.do {
        arg instr;
        Pdef((instr ++ "_pat").asSymbol).quant = -1;
        Pdef((instr ++ "_pat").asSymbol).play;
    };

    g = Group.new(s);

    Tdef(\sweep_task).quant = -1;
    Tdef(\sweep_task, {
        var old_cutoff = 0;
        var cutoff = Pn(Plazy({
            var seq = [[ 0, 0, 0, 0], { 2.rand } ! 4].wchoose([0.7, 0.3]);
            var cutoff = seq * ({ 1e3.exprand(10e3) } ! 4);
            seq.postln;
            Pseq(cutoff);
        })).asStream;

        var lag_time = Pseq([0.05, 0, 2, 0], inf).asStream;

        loop {
            ~sweep_control.set(\cutoff, cutoff.next, \lag_time, lag_time.next);
            8.wait;
        };
    }).play;

    Pdef(\sidechain).quant = -1;
    Pdef(\sidechain_pat, Pbind(
        \instrument, \sidechain,
        \dur, 1
    )).play;


    fork {
        var is_playing = true;
        var bar_count = 0;
        var state = 0;
        var attention_mean = 0;
        var attention_mean_calc = [ 1.0.rrand(1.5),  1.7.rrand(2.0), 0.9, 2.2.rrand(3.0), 0.0]*1/2;

        // ("The time is "++Date.getDate.format("%H:%M") ++ " and you're listening to Techno Generator 3000").speak;

        var form = Pfsm([
            #[ 0 ],
            0, #[ 0, 1 ],
            1, #[ 1, 2],
            2, #[ 2, 3 ],
            3, #[ 1, 0 ],
            nil, nil
        ], inf).asStream;

        var state_counter = Pseries(0, 1, 10).asStream;


        while({ is_playing }, {
            var seq, attention_array, tmp, deviation = 0.3, mu = 0, dev = 0, median, swing = 0.0.rrand(0.5);
            if (bar_count == 0, {
                var count = state_counter.next;
                ("Progress: "++count).postln;

                if (count == nil, {
                    is_playing = false;

                });

                attention_mean = attention_mean_calc[state];

                ("State: "++state).postln;
                state = form.next;
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

    var reverb = GVerb.ar(reverb_in[0], 100.rrand(150), 1.rrand(4.0), 0.5, 0.5, 15, drylevel: 0, earlyreflevel: 0.1, taillevel: 2);
    var delaytime = 60/Tempo.bpm * [4/3, 2/3, 1/2, 1/4, 1/8, 1/6].choose;
    var delay = AllpassC.ar(delay_in, delaytime, delaytime, 2);

    var mix = master_in + delay + Compander.ar(reverb, In.ar(~sidechain) * 4, 0.1, 1, 1/4, 0.05, 0.2);
    var compressor = Compander.ar(mix, mix, 0.08, 1, 1/3, 0.02, 0.05) * 1;
    var master_out =  Limiter.ar(compressor, 0.97, 0.02);

    ReplaceOut.ar(0, master_out);

}.play(g, addAction: \addToTail);
)
2**63