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
var num_grains = 250;
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
    var attention_mean = 0;
    var attention_mean_calc = [ 8, 15, 5, 20] * ~attention_scale;

    var form = Pfsm([
        #[ 0 ],
        0, #[ 0, 1, 1, 1 ],
        1, #[ 1, 2, 2, 2 ],
        2, #[ 2, 3, 3, 3 ],
        3, #[ 3, 3, 3, 1, 0 ],
        nil, nil
    ], inf).asStream;

    var state_counter = Pseries(0, 1, 10).asStream;

    // ("The time is "++Date.getDate.format("%H:%M") ++ " and you're listening to Techno Generator 3000").speak;

    var instr_list = [\bd, \hat ] ++ ({ ~all_instruments.choose } ! 7);
    var instr_in_state = {arg i; instr_list[..i+4] } ! 4;
    // var instr_in_state = {[\bass, \bd, \chords, \hat, \hat909, \clap909 ] } ! 4;
    var bars =  [ 1, 2, 4 ].choose;
    instr_in_state.postln;
    // bars = [ 1 ].choose;
    t =  123.rrand(135);
    Tempo.bpm = t;

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
        while({ is_playing }, {
            var seq = (), tmp, mu = 0, dev = 0, median, swing = 0.0.rrand(0.5);
            if (bar_count == 0, {
                var count = state_counter.next;
                ("Progress: "++count).postln;

                if (count == nil, {
                    is_playing = false;

                });

                state = form.next;
                attention_mean = attention_mean_calc[state];
                ("State: "++state).postln;

            });

            ("bar "++bar_count).postln;



            // Creates the 4-bar feelin'
            if(bar_count > 2, {
                attention_mean = [ attention_mean * 0.75, attention_mean * 1.25].choose;
            });

            swing = 0;
            // ----------------------------------------
            {
                var n_tests = 1;
                var mean = inf, variance = inf, selected_seq = 0, sum = 0, tmp_seq = () ! n_tests, attention_array = (0 ! (res*bars)) ! n_tests;
                // Iterate through grain array
                n_tests.do {
                    arg i;
                    var data, mu, vari, ref, k;

                    k = (0, 2pi/res..(2*bars*pi) - (2pi/res));

                    ref = (0..((bars*4)-1)).sum{ arg n;
                        x = ((k*res/2) - ((((res/4)*n)+(res/8))*pi)) * pi;
                        x = x.replace([0], [1e-20]);
                        x.sin/x;
                    };

                    ref = (0.1 + ref) * attention_mean;


                    // ----- Fill sequence with silence -------
                    ~all_instruments.do {
                        arg instr;
                        // Add all instruments to sequence
                        tmp_seq[i].add(instr -> ());
                        tmp_seq[i][instr].add(\sustained -> false);
                        tmp_seq[i][instr].add(\seq -> ());
                        // Iterate through attributes
                        ~default_attributes[instr].keysValuesDo {
                            arg key, value;
                            // For each attribute add a list of repeated default values
                            tmp_seq[i][instr][\seq].add(key -> (value ! (res * bars)));
                        }
                    };

                    grains.do {
                        arg grain;
                        var tmp = attention_array[i].copy;
                        var tmp_mu;

                        tmp[grain[\index]] = tmp[grain[\index]] + grain[\attention];

                        // if ((tmp_mu <= attention_mean) && (instr_in_state[state].find([grain[\instrument]]) != nil), {

                        if ((tmp[grain[\index]] <= ref[grain[\index]]) && (instr_in_state[state].find([grain[\instrument]]) != nil), {
                            attention_array[i] = tmp;

                            grain[\attributes].keysValuesDo {
                                arg key, value;
                                tmp_seq[i][grain[\instrument]][\seq][key][grain[\index]] = value;
                            };
                        });
                    };

                    data = attention_array[i];
                    mu = data.mean;
                    vari = ((data - mu)**2).sum/(data.size);
                    sum = data.sum;

                    // if ((mu < mean), {
                    if ((abs(mu-attention_mean) < mean) && (vari < variance), {
                        mean = abs(mu-attention_mean);
                        variance = vari;
                        selected_seq = i;
                    });
                };
                seq = tmp_seq[selected_seq];
                selected_seq.postln;
            }.();

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
            };
            (seq_duration*bars).wait;
            bar_count = (bar_count + 1) % 4;
        });

        Buffer.freeAll;
        ~create_song.value;
    };
};

~create_song.value;

{
    var pad_in = In.ar(~chords_fx, 2);
    var pad_out = pad_in + Mix(DelayC.ar(pad_in, 0.2, SinOsc.kr(Rand(0.07, 0.1) ! 2, Rand(0, 2pi) ! 2, 0.009, 0.01), 0) ! 8);

    var master_in = In.ar(0, 2);
    var delay_in = (pad_out * 0.3) + In.ar(~delay, 2);
    var reverb_in = (pad_out * 0.1) + In.ar(~reverb, 2);


    var reverb = GVerb.ar(reverb_in[0], 100.rrand(150), 1.rrand(4.0), 0.5, 0.5, 15, drylevel: 0, earlyreflevel: 0.0, taillevel: 1);
    var delaytime = 60/Tempo.bpm * [4/3, 2/3, 3/2, 1,  5/4, 6/8, 5/6].choose;
    var delay = AllpassC.ar(delay_in, delaytime, delaytime, 2, 0.5);

    var mix = master_in + delay + pad_out + reverb;
    var compressor = Compander.ar(mix, mix, 0.1, 1, 1/3, 0.02, 0.05) * 7;
    var master_out =  Limiter.ar(compressor, 0.97, 0.02);



    ReplaceOut.ar(0, master_out);

}.play(g, addAction: \addToTail);
)
