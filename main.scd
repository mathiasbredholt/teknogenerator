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
var res = 64;
var num_grains = 2000;
var seq_duration = 4;
var seed = (2**15).rand.round;
//var seed = 28654;
var root, scale, grains, state_rand;

s.latency = 0.2;

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
// 23376

~bass_p.set(0 ! 8);
Synth(\bass_real);
~sweep_control = Synth(\sweep_control);




("seed: " + seed).postln;


~create_song = {
    var is_playing = true;
    var bar_count = 0;
    var state = 0;
    var attention_max = 0;
    var attention_max_in_state = [ 1, 1, 0.15, 1.5 ] * ~attention_scale;

    var form = Pfsm([
        #[ 3 ],
        0, #[ 0, 1, 1, 1 ],
        1, #[ 1, 2, 2, 2 ],
        2, #[ 2, 3, 3, 3 ],
        3, #[ 3, 3, 3, 1, 0 ],
        nil, nil
    ], inf).asStream;

    var state_counter = Pseries(0, 1, 10).asStream;

    // ("The time is "++Date.getDate.format("%H:%M") ++ " and you're listening to Techno Generator 3000").speak;

    var instr_available = ~all_instruments.copy.removeAll([\bd, \hat, \chords]);
    var instr_list = [\bd, \hat, \chords ] ++ ({
        x = instr_available.choose;
        instr_available.remove(x);
        x;
    } ! 7);
    var instr_in_state = {arg i; instr_list[..i+4] } ! 4;
    var bars =  [ 1, 2, 4 ].choose;
    Tempo.bpm = 123.rrand(135);

    // Generate array of random grains
    root = 55.rrand(66);
    scale = [ Scale.minor ].choose;
    ~init_generation.value;
    grains = { ~generate.value(Tempo.bpm, scale, root, res, bars) } ! num_grains;

    // translates from
    //(\instrument: \bd, \beat_tag: \basebeat, \sustained: false, \attention: 2, \attributes: (\amp: 0.1))
    // to
    // (\bd: (\sustained: false, \seq: (\amp: [1, 0, 1, 0, 1, 0, 1 ..], \type: [rest, note, rest, note ...])))
    // 1, 0, 1, 0, 1, 0, 1, ...
    // rest, note, rest, note ...

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
            var seq = [[ 0, 0, 0, 0], [ 0, 0, 1, 1 ]].wchoose([0.9, 0.1]);
            var cutoff = seq * ({ 1e3.exprand(10e3) } ! 4);
            Pseq(cutoff);
        })).asStream;
        var lag_time = Pseq([ 0.05, 0, 2, 2 ], inf).asStream;
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
        while({ is_playing }, {
            var seq = (), median, swing = 0.0.rrand(0.5);
            if (bar_count == 0, {
                var count = state_counter.next;
                ("Progress: "++count).postln;

                if (count == nil, {
                    is_playing = false;

                });
                state = form.next;
                attention_max = attention_max_in_state[state];
                ("State: "++state).postln;

            });

            ("bar "++bar_count).postln;



            // Creates the 4-bar feelin'
            if(bar_count > 2, {
                attention_max = attention_max * 0.75;
            });

            "attention".postln;
            attention_max.postln;
            swing = 0.0;

            {
                // Create array of zeros with the length of the whole sequence
                var attention_array = 0 ! (res*bars);
                var ref, k, c;
                // Create the discrete time vector
                k = (0, 1/res..bars - (1/res));
                // Scaling coefficient, 0.5 and 1 for odd and even values of n
                c = Pseq([ 0.5, 1 ], inf).asStream;
                // Create discrete reference function
                ref = (0..(( bars * 4 ) - 1)).sum {
                    arg n;
                    x = ((( 2pi*2*k ) - ((n + (1/2) ) * pi))) * pi;
                    x = x.replace([ 0 ], [ 1e-20 ]);
                    c.next * ( x.sin / x);
                };
                // Scale, add offset and clip the function
                ref =  ((ref * attention_max) + (attention_max/2));
                // Fill sequence with silence
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

                // Iterate through grains
                grains.do {
                    arg grain;
                    // If the instrument should be in the sequence in the current state
                    if (instr_in_state[state].find([grain[\instrument]]) != nil, {
                        // Copy attention array and add the current grain
                        var tmp = attention_array.copy;
                        var index = grain[\index];
                        tmp[index] = tmp[index] + grain[\attention];
                        // Check if the new attention array follows the reference function

                        if (tmp[index] <= ref[index], {
                            // The grain is added to the sequence
                            attention_array = tmp;
                            grain[\attributes].keysValuesDo {
                                arg key, value;
                                seq[grain[\instrument]][\seq][key][index] = value;
                            };
                        });
                    });

                };

                // attention_array.
                // mu = data.mean;
                // vari = ((data - mu)**2).sum/(data.size);
                // sum = data.sum;
                //
                // // if ((mu < mean), {
                // if ((abs(mu-attention_max) < mean) && (vari < variance), {
                //     mean = abs(mu-attention_max);
                //     variance = vari;
                //     selected_seq = i;
                // });
            }.();

            // Iterate through all instruments in sequence
            seq.keysValuesDo {
                // key is instrument, attributes is seq
                arg key, attributes;
                var pattern = ();

                // For each instrument attribute at a Pseq containing the sequence of values
                attributes[\seq].keysValuesDo {
                    arg key, value;
                    pattern.add(key->Pseq(value, inf));
                };

                // Create patterns for each instrument and chain them with swingify, a custom pattern to add swing
                Pdef((key ++ "_pat").asSymbol, Pchain(~swingify, Pbind(
                    \instrument, key,
                    \group, g,
                    \dur, 4/res,
                ), Pbind(*pattern.asPairs), (swingBase: 0.5, swingAmount: swing, swingThreshold: 0.1)));
            };
            (4*bars).wait;
            bar_count = (bar_count + 1) % 4;
        });

        Buffer.freeAll;
        ~create_song.value;
    };
};

~create_song.value;

{
    // Read input from global bus
    var chorus_in = In.ar(~chorus, 2);
    // Add delayed versions of input signal with modulated delay times
    var chorus = chorus_in + Mix(DelayC.ar(chorus_in, 0.2, SinOsc.kr(Rand(0.07, 0.1) ! 2, Rand(0, 2pi) ! 2, 0.009, 0.01), 0) ! 8);

    var master_in = In.ar(0, 2);
    var delay_in = (chorus * 0.3) + In.ar(~delay, 2);
    var reverb_in = (chorus * 0.1) + In.ar(~reverb, 2);

    var reverb = GVerb.ar(reverb_in[0], 100.rrand(150), 1.rrand(4.0), 0.5, 0.5, 15, drylevel: 0, earlyreflevel: 0.0, taillevel: 1);
    var delaytime = 60/Tempo.bpm * [4/3, 2/3, 3/2, 1,  5/4, 6/8, 5/6].choose;
    var delay = AllpassC.ar(delay_in, delaytime, delaytime, 2, 0.5);

    var mix = master_in + delay + chorus + reverb;
    var compressor = Compander.ar(mix, mix, 0.1, 1, 1/3, 0.02, 0.05) * 10;
    var master_out =  Limiter.ar(compressor, 0.97, 0.02);
    // Replaces all outputs with the mastered signal
    ReplaceOut.ar(0, master_out);
}.play(g, addAction: \addToTail);
)
