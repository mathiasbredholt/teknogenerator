(
~sidechain = 20;
~reverb = 22;
~delay = 24;
~bass_p = Bus.control(s, 8) ; // amp, freq, rez, filter_release, cutoff, distort, reverb, gate
)

(
SynthDef(\bd, {
    arg amp = 1, freq = 50, sustain_time = 0, release = 1, distort = 0;
    var aEnv = EnvGen.kr(Env.linen(1e-3, sustain_time, 0.05, 1, -4), doneAction: 2);
    var sig = Ringz.ar(Impulse.ar(0.1), freq, release) * 0.1 * amp * aEnv;
    sig = (sig * (1-distort)) + ((sig * distort.linexp(0, 1, 1, 100)).distort * distort.linexp(0, 1, 1, 0.01)) * aEnv * 2;
    Out.ar(0, sig ! 2);
    Out.ar(~sidechain, sig ! 2);
}).add;

SynthDef(\sd, {
    arg amp = 0.1, release = 0.02, reverb = 0.1;
    var aEnv = EnvGen.kr(Env.perc(1e-3, release), doneAction: 2);
    var sig = WhiteNoise.ar * aEnv * amp;
    sig = sig + (SinOsc.ar(300, 0, 0.5) * aEnv);
    Out.ar(0, sig * 0.1 ! 2);
    // Out.ar(~reverb, sig * reverb ! 2);
}).add;

SynthDef(\clap, {
    arg amp = 1, release = 0.1, reverb = 0, lfo = 50, cutoff = 1e3, distort = 0.5;
    // var aEnv = EnvGen.kr(Env([1, 0, 1, 0, 1, 0], [ time, 0, time, 0, time], -4), doneAction: 2);
    var aEnv = EnvGen.kr(Env.perc(1e-3, release), doneAction: 2);
    var aEnv2 = LFPulse.kr(lfo).range(0,1) * EnvGen.kr(Env.linen(1e-3, 0.02 + (release * 0.15), 0, 1));
    var sig = Mix(BBandPass.ar([ WhiteNoise.ar * aEnv2, WhiteNoise.ar * 0.1 * aEnv ], [cutoff, 8e3], 4)) * 0.5 * amp;
    sig = [sig, DelayC.ar(sig, 0.0007, 0.0007)];
    sig = (sig * (1-distort)) + ((sig * distort.linexp(0, 1, 1, 100)).distort * distort.linexp(0, 1, 1, 0.15));
    Out.ar(0, sig * 0.5);
    // Out.ar(~reverb, HPF.ar(sig, 4e3) * reverb);
}).add;

SynthDef(\hat,{
    arg amp = 0.1, attack = 1e-3, release = 0.1, cutoff = 1000, reverb = 0.01;
    var sig = SinOsc.ar(5e3 + LFTri.ar(5e3, 0, 5e3 * 15));
    var aEnv = EnvGen.kr(Env.perc(attack, release, 1, -6), doneAction: 2);
    sig = (WhiteNoise.ar + sig) * aEnv * 0.02 * amp;
    sig = HPF.ar(sig, cutoff);
    Out.ar(0, sig ! 2);
    // Out.ar(~reverb, sig * reverb ! 2);
}).add;

SynthDef(\tone, {
    arg amp = 0.1, attack = 0.01, release = 0.5, freq = 220, dist = 10, chorus = 0, rate = 10;
    var aEnv = EnvGen.kr(Env.perc(attack, release),doneAction: 2);
    var freq_mod = (SinOsc.kr(rate,0,chorus)- chorus/2)*100;
    var sig = Saw.ar([freq*1.01+freq_mod,freq*0.99+freq_mod]);
    sig = BPF.ar(sig,freq,0.5) *amp * aEnv;

    /* ---------Effects-------------- */

    //Distortion
    sig = (dist) * sig / (1 + (dist * sig.abs));

    Out.ar(0,sig);
}).add;


SynthDef(\iron, {
    arg amp = 0.1, attack = 0.03, release = 0.5, freq = 400, delay = 0.1;
    var harms = [0.56,0.92,1.19,1.71,2,2.74,3,3.76,4.07];
    var aEnv = EnvGen.kr(Env.perc(attack, release, curve: -4),doneAction: 2);
    var sig = SinOsc.ar(freq+LFNoise2.kr(10,5));
    harms.do({
        arg harm, index;
        var i = index-(2*index)+1; // LOL hjælp med bedre både at skrive -index
        sig = sig + (SinOsc.ar(harm*freq,1/2pi*index)*(2**i) * EnvGen.kr(Env.perc(attack*(1/index),release*(1/(index+1)),curve: \sine)));
    });

    sig = sig + AllpassC.ar(sig,delay,delay,2,0.2);
    sig = sig * amp*aEnv + (BPF.ar(WhiteNoise.ar,2e3,mul:0.1)*EnvGen.kr(Env.perc(0.01,0.05)));
    Out.ar(0,sig ! 2);
}).add;



SynthDef(\cymbal, {
    // Cymbal sound made with resonatorbanks of fixed exponentially distributed frequencies.
    arg release = 10, amp = 1;
    var lodriver, locutoffenv, hidriver, hicutoffenv, freqs, sig;

    //
    var ampEnv = EnvGen.ar(Env.perc(0,0.1));
    var freqEnv = EnvGen.ar(Env.perc(0,0.4))*15e3;
    var excitation = Klank.ar(`[{exprand(300, 20000)}.dup(100), nil, { 0.3 }.dup(100)], Impulse.ar(0.1)) * 1/100;
    excitation = BLowPass4.ar(excitation ,freqEnv+500, 0.4)*ampEnv;

    // Driver for low frequencies to filterbank,
    locutoffenv = EnvGen.ar(Env.perc(0.5, release)) * 20000 + 100;
    lodriver = LPF.ar(WhiteNoise.ar(0.1), locutoffenv);

    //Driver for high frequencies to filterbank + amplitude attenuation
    hicutoffenv = XLine.kr(50,4e3, 0.2);
    hidriver = BHiPass4.ar(WhiteNoise.ar(0.1), hicutoffenv, 2);
    hidriver = hidriver * EnvGen.ar(Env.perc(1, 2, release/10)) * 3;

    //Exponential frequency distribution
    freqs  = {exprand(300, 20000)}.dup(200);
    sig = Klank.ar(`[freqs, nil, { 2 }.dup(200)], lodriver + hidriver + excitation) * 1/200;

    // The hit is added to signal, together with some of the low driving noise
    sig = ((sig * 1) + (lodriver * 2) + (excitation * 2)).dup;
    sig = sig *EnvGen.ar(Env.perc(1e-3, release, 1, -64), doneAction: 2);

    Out.ar(~reverb, (sig * 100).distort*0.02*amp ! 2);


}).add;

SynthDef(\ride,{
    arg release = 1, amp = 0.5;
    var ampEnv = EnvGen.ar(Env.perc(0,release, 1, -8),doneAction: 2);
    var freqEnv = EnvGen.ar(Env.perc(0,release*0.8))*20000;
    var sig = Klank.ar(`[{exprand(500, 20000)}.dup(100), nil, { release }.dup(100)], Impulse.ar(0.1)) * 1/100;
    sig = LPF.ar(sig,freqEnv+500);
    sig = sig * ampEnv;

    Out.ar(~reverb, sig * amp ! 2);
}).add;

SynthDef(\bass_real, {
    var p = In.kr(~bass_p, 8);
    var amp = p[0],
    freq = p[1],
    rez = p[2],
    filter_release = p[3],
    cutoff = p[4],
    distort = p[5],
    reverb = p[6],
    gate = p[7];
    var aEnv = EnvGen.kr(Env.adsr(0.05, 1, 1, 0.05), gate);
    var fEnv = EnvGen.kr(Env.perc(0.05, 0.2), gate, cutoff - 0.5e3, 0.5e3);
    var sig = Mix(LFSaw.ar(Lag.kr(freq, 0.3) * Rand(0.99, 1.01) ! 2, Rand(0, 1), 0.3)) * 0.3 * amp;
    sig = MoogLadder.ar(sig, fEnv, rez) * 0.3 * aEnv;
    sig = (sig * (1-distort)) + ((sig * distort.linexp(0, 1, 1, 100)).distort * distort.linexp(0, 1, 1, 0.02)) * aEnv * 0.2;
    sig = sig + Mix(DelayC.ar(sig, 0.2, SinOsc.kr(Rand(0.07, 0.1) ! 2, Rand(0, 2pi) ! 2, 0.03, 0.08), 0.02) ! 8);
    sig = Compander.ar(sig, InFeedback.ar(~sidechain) * 2, 0.1, 1, 1/4, 0.01, 0.2);
    Out.ar(0, sig ! 2);

    // Out.ar(~reverb, sig * reverb ! 2);
}).add;

SynthDef(\bass, {
    arg amp, freq, rez, filter_release, cutoff, distort, reverb, gate = 1;
    ReplaceOut.kr(~bass_p, [amp, freq, rez, filter_release, cutoff, distort, reverb, gate]);
    EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);
}).add;

SynthDef(\pad, {
    arg freq = 100, amp = 1, sustain_time = 2, cutoff = 100, env_type = 0, reverb = 0.2, delay = 0.6, rez = 0.4;
    var aEnv = Select.kr(env_type, [
        EnvGen.kr(Env.linen(0.1, sustain_time, 0.1, 1, -4)),
        EnvGen.kr(Env.perc(1e-3, 1))
    ]);
    var fEnv = Select.kr(env_type, [
        EnvGen.kr(Env.linen(1, sustain_time), 1, cutoff - freq, freq),
        EnvGen.kr(Env.perc(1e-3, 0.3), 1, cutoff - freq, freq)
    ]);
    var sig = Mix(
        LFSaw.ar(
            (freq * Rand(0.998, 1.002) ! 2) * SinOsc.kr(Rand(0.5, 1), Rand(0, 2pi)).range(0.998, 1.002) ! 4,
            Rand(0, 1),
            0.3
        )
    ) * 0.02 * aEnv * amp;
    sig = BLowPass.ar(sig, fEnv, rez);
    sig = sig + Mix(DelayC.ar(sig, 0.2, SinOsc.kr(Rand(0.07, 0.1) ! 2, Rand(0, 2pi) ! 2, 0.03, 0.1), 0.04) ! 8);
    Out.ar(0, sig);
    Out.ar(~reverb, sig*reverb);
    Out.ar(~delay, sig*delay);
    EnvGen.kr(Env.linen(0.1, sustain_time, 1), doneAction: 2);
}).add;


SynthDef(\fm_stab, {
    arg freq = 50, amp = 0.1, attack = 0.1, release = 0.5, detune = 0.5;
    var partials = [ 1+detune, 2+detune, 4+detune, 12+detune];
    var indexes = [ 1, 2, 4, 8];
    var fm = 0;
    var aEnv = EnvGen.ar(Env.perc(attack,release),doneAction: 2);
    var fEnv = EnvGen.ar(Env.perc(0.01,0.2));
    partials.size.do {
        arg n;
        var modfreq = freq*partials[n];
        fm = SinOsc.ar([modfreq*Rand(0.9999, 1.0001), modfreq*Rand(0.9999, 1.0001)], 0, modfreq*indexes[n], fm);
    };


    fm = SinOsc.ar(freq + fm, Saw.kr(0.5).range(-2pi,2pi));
    fm = fm * aEnv;
    fm = BBandPass.ar(fm,freq+(fEnv*1000),1.5);
    Out.ar(0,(fm*amp));
}).add;

SynthDef(\bell, {
    arg gate=1, freq=100, decay=0.6, amp=1, reverb = 0.05, distort = 1, delay = 0.5;
    var excitation, sig, aEnv, fEnv;
    excitation = WhiteNoise.ar(EnvGen.ar(Env.perc(0.0000001, 0.01)));
    sig = Klank.ar(`[
        // frequency ratios
        [0.501, 1, 0.7,   2.002, 3, 9.6,   2.49, 11, 2.571,  3.05, 6.242, 12.49, 13, 16, 24],
        // amps
        [0.002,0.02,0.001, 0.008,0.02,0.004, 0.02,0.04,0.02, 0.005,0.05,0.05, 0.02, 0.03, 0.04],
        // ring times
        [1.2, 0.9, 0.25, 0.14, 0.07].stutter(3)
    ]
    , excitation, freq, 0, decay);
    aEnv = EnvGen.ar(Env.perc(1e-3,decay),doneAction: 2);
    sig = (sig+excitation) * amp;
    sig = (sig * (1-distort)) + ((sig * distort.linexp(0, 1, 1, 100)).distort * distort.linexp(0, 1, 1, 0.02));
    Out.ar(0, sig ! 2);
    Out.ar(~reverb, sig*reverb ! 2);
    Out.ar(~delay, sig*delay ! 2);
}).add;


)
