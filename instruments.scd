(
s.waitForBoot({
    ~sidechain = 20;
    ~reverb = 22;
    ~delay = 24;
    ~chorus = 26;
    ~bass_p = Bus.control(s, 8) ; // amp, freq, rez, filter_release, cutoff, distort, reverb, gate
    ~sweep = Bus.control.set(0);


    SynthDef(\sidechain, {
        ReplaceOut.ar(~sidechain, Ringz.ar(Impulse.ar((4*60)/127), 50, 0.4) ! 2);
        Line.kr(dur: 0.4,doneAction: 2);
    }).add;


    SynthDef(\hat909, {
        arg amp = 0.1, attack = 0.01, sustain_time = 1, distort = 0, bufnum, rate = 1;
        var sig, aEnv;
        aEnv = EnvGen.kr(Env.linen(attack, sustain_time, 0.05 ,curve: -4),doneAction: 2);
        sig = PlayBuf.ar(1,bufnum,rate * BufRateScale.kr(bufnum)) * aEnv * amp;
        sig = (sig * (1-distort)) + ((sig * distort.linexp(0, 1, 1, 100)).distort * distort.linexp(0, 1, 1, 0.01)) * 0.2;
        sig = BPeakEQ.ar(sig, 8000, 2, 15);
        Out.ar(0,sig ! 2)
    }).add;


    SynthDef(\clap909, {
        arg amp = 0.1, attack = 0.01, sustain_time = 1, distort = 0, bufnum, rate = 1;
        var sig, aEnv;
        aEnv = EnvGen.kr(Env.linen(attack, sustain_time, 0.05 ,curve: -4),doneAction: 2);
        sig = PlayBuf.ar(1,bufnum,rate * BufRateScale.kr(bufnum)) * aEnv * amp;
        sig = (sig * (1-distort)) + ((sig * distort.linexp(0, 1, 1, 100)).distort * distort.linexp(0, 1, 1, 0.01)) * 0.1;
        sig = BPeakEQ.ar(sig, 8000, 2, 15);
        Out.ar(0,sig ! 2)
    }).add;

    SynthDef(\bd, {
        arg amp = 1, freq = 50, sustain_time = 0, release = 1, distort = 0;
        var aEnv = EnvGen.kr(Env([0, 1, 1, 0], [1e-3, sustain_time, 0.1], -4), doneAction: 2);
        var sig = Ringz.ar(Impulse.ar(0.1), freq, release) * 0.1 * amp * aEnv;
        sig = (sig * (1-distort)) + ((sig * distort.linexp(0, 1, 1, 100)).distort * distort.linexp(0, 1, 1, 0.01)) * aEnv * 0.5;
        sig = HPF.ar(sig, 20 + Lag2.kr(In.kr(~sweep), 0.1));
        Out.ar(0, sig ! 2);
    }).add;

    SynthDef(\sd, {
        arg amp = 0.1, release = 0.02, reverb = 0.1;
        var aEnv = EnvGen.kr(Env.perc(1e-3, release), doneAction: 2);
        var sig = WhiteNoise.ar * aEnv * 0.2 * amp;
        sig = sig + (SinOsc.ar(300, 0, 0.3) * aEnv);
        sig = sig * 0.5;
        sig = sig + DelayC.ar(sig, 0.05, 0.05, 0.5);
        Out.ar(0, sig * 0.1 ! 2);
        // Out.ar(~reverb, sig * reverb ! 2);
    }).add;

    SynthDef(\clap, {
        arg amp = 1, release = 0.1, reverb = 0.5, lfo = 50, cutoff = 1e3, distort = 0.5;
        // var aEnv = EnvGen.kr(Env([1, 0, 1, 0, 1, 0], [ time, 0, time, 0, time], -4), doneAction: 2);
        var aEnv = EnvGen.kr(Env.perc(1e-3, release), doneAction: 2);
        var aEnv2 = LFPulse.kr(lfo).range(0,1) * EnvGen.kr(Env.linen(1e-3, 0.02 + (release * 0.15), 0, 1));
        var sig = Mix(BBandPass.ar([ WhiteNoise.ar * aEnv2, WhiteNoise.ar * 0.1 * aEnv ], [cutoff, 8e3], 4)) * 0.05 * amp;
        sig = [sig, DelayC.ar(sig, 0.0007, 0.0007)];
        sig = (sig * (1-distort)) + ((sig * distort.linexp(0, 1, 1, 100)).distort * distort.linexp(0, 1, 1, 0.15));
        Out.ar(0, sig * 0.25);
        Out.ar(~reverb, sig * reverb);
    }).add;

    SynthDef(\hat,{
        arg amp = 0.1, attack = 1e-3, release = 0.1, cutoff = 1000, reverb = 1;
        var sig = SinOsc.ar(5e3 + LFTri.ar(5e3, 0, 5e3 * 15));
        var aEnv = EnvGen.kr(Env.perc(attack, release, 1, -6), doneAction: 2);
        sig = (WhiteNoise.ar + sig) * aEnv * 0.04 * amp;
        sig = HPF.ar(sig, cutoff);
        sig = [sig, DelayC.ar(sig, 0.002, 0.002)];
        Out.ar(0, sig);
        Out.ar(~reverb, sig * reverb);
    }).add;

    SynthDef(\spectral_noise, {
        arg amp = 0.2, cutoff = 500, rez = 0.5, phase = 0, teeth = 40;
        // Band-pass filtered gray noise
        var ampEnv = EnvGen.kr(Env.linen(0.15, 0, 0.03 ,1, -4), doneAction: 2);
        var sig = BPF.ar(GrayNoise.ar * amp, cutoff + (In.kr(~sweep) * 2), 0.4);
        // Transform to frequency domain, apply comb, and transform back to time
        sig = IFFT(PV_RectComb(FFT(LocalBuf(2048), sig), teeth, phase, 0.05));
        // Increase amplitude with sweep
        sig = sig * ampEnv * LinLin.kr(In.kr(~sweep), 0, 5e3, 0.15, 0.6);
        Out.ar(0, sig ! 2);
        Out.ar(~reverb, sig ! 2);
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


    SynthDef(\membrane, {
        arg amp = 0.05, attack = 0.03, release = 0.5, freq = 600, delay = 0.1, reverb = 0.2;
        var harms = [ 0.56, 0.92, 1.19, 1.71, 2, 2.74, 3, 3.76, 4.07 ];
        var ampEnv = EnvGen.kr(Env.perc(attack, release), doneAction: 2);

        var sig = SinOsc.ar(freq + LFNoise2.kr(10, 5));
        sig = sig + DynKlang.ar(`[
            harms,
            harms.size.collect {
                arg i;
                (2**(i-1).neg) * EnvGen.kr(Env.perc(attack/i, release/(i+1), curve: \sine));
            },
            Rand(0, 2pi)
        ], freq);

        sig = sig + AllpassC.ar(sig, delay, delay, 2, 0.2);
        sig = sig * amp * ampEnv + (
            BPF.ar(WhiteNoise.ar, 2e3, 1, 0.1) * EnvGen.kr(Env.perc(0.01, 0.05))
        );
        sig = BPeakEQ.ar(sig, 100, 1, -10);
        sig = sig * 0.1;
        Out.ar(~reverb, sig * reverb ! 2);
        Out.ar(0,sig ! 2);
    }).add;

    SynthDef(\cymbal, {
        // Cymbal sound made with resonatorbanks of fixed exponentially distributed frequencies.
        arg release = 10, amp = 1;
        var lodriver, locutoffenv, hidriver, hicutoffenv, freqs, sig;

        //
        var ampEnv = EnvGen.ar(Env.perc(0.005,0.1));
        var freqEnv = EnvGen.ar(Env.perc(0.1,0.4))*15e3;
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
        Out.ar(0, (sig * 100).distort*0.01*amp ! 2);
        Out.ar(~reverb, (sig * 100).distort*0.2*amp ! 2);

    }).add;

    SynthDef(\ride,{
        arg release = 1, amp = 0.5;
        var ampEnv = EnvGen.ar(Env.perc(0.005,release, 1, -8),doneAction: 2);
        var freqEnv = EnvGen.ar(Env.perc(0.1,release*0.8))*20000;
        var sig = Klank.ar(`[{exprand(500, 20000)}.dup(100), nil, { release }.dup(100)], Impulse.ar(0.1)) * 1/100;
        sig = LPF.ar(sig,freqEnv+500);
        sig = sig * ampEnv;
        sig = sig * 0.4;
        Out.ar(0, sig * 0.1 * amp ! 2);
        Out.ar(~reverb, sig * 0.5 * amp ! 2);
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
        var aEnv = EnvGen.kr(Env.adsr(0.05, 0.05,  0.7, 0.05), gate);
        var fEnv = EnvGen.kr(Env.adsr(0.05, 0.05, 0.5, 0.05), gate, 1e3 - 0.3e3, 0.3e3 + In.kr(~sweep));
        var sig = (SinOsc.ar(Lag.kr(freq, 0.4), 0, 1) + Mix(LFSaw.ar(Lag.kr(freq, 0.4) * Rand(0.99, 1.01) ! 4, Rand(0, 1), 0.3))) * 0.1 * amp;
        sig = BLowPass4.ar(sig, fEnv, 1) * 0.5 * aEnv;

        // sig = (sig * (1-distort)) + ((sig * distort.linexp(0, 1, 1, 100)).distort * distort.linexp(0, 1, 1, 0.02)) * aEnv;
        // sig = sig + Mix(DelayC.ar(sig, 0.2, SinOsc.kr(Rand(0.07, 0.1) ! 2, Rand(0, 2pi) ! 2, 0.03, 0.08), 0.03) ! 8);
        sig = Compander.ar(sig, InFeedback.ar(~sidechain), 0.1, 1, 1/4, 0.01, 0.2);
        Out.ar(0, sig ! 2);

        // Out.ar(~reverb, sig * reverb ! 2);
    }).add;

    SynthDef(\bass, {
        arg amp, freq, rez, filter_release, cutoff, distort, reverb, gate = 1;
        ReplaceOut.kr(~bass_p, [amp, freq, rez, filter_release, cutoff, distort, reverb, gate]);
        EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);
    }).add;

    SynthDef(\chords, {
        arg freq = 500, amp = 1, sustain_time = 2, cutoff = 100, filter_release = 0.03, reverb = 0.2, delay = 0.6, rez = 0.4;
        var aEnv = EnvGen.kr(Env.new([0, 1, 0.5, 0], [0.01, sustain_time, 0.05], -4), doneAction: 2);
        var fEnv = EnvGen.kr(Env.perc(1e-3, filter_release), 1, cutoff - freq, freq + In.kr(~sweep));
        var sig = Select.ar(IRand(0, 1), [
            LFSaw.ar(
                freq * Rand(0.995, 1.005) ! 2,
                Rand(0, 1),
                0.3
            ),
            LFPulse.ar(
                freq * Rand(0.995, 1.005) ! 2,
                Rand(0, 1),
                Rand(0, 1),
                0.3
            )
        ]) * 0.1 * aEnv * amp;
        sig = BLowPass.ar(sig, fEnv, 0.3);
        Out.ar(~chorus, sig);
    }).add;

    SynthDef(\pads, {
        arg freq = 500, amp = 1, sustain_time = 2, cutoff = 100, reverb = 0.4, delay = 0.6, rez = 0.4;
        var aEnv = EnvGen.kr(Env.new([0, 1, 1, 0], [0.1, sustain_time, 0.1], -4), doneAction: 2);
        var sig = Select.ar(IRand(0, 1), [
            LFSaw.ar(
                freq * Rand(0.995, 1.005) ! 2,
                Rand(0, 1),
                0.3
            ),
            LFPulse.ar(
                freq * Rand(0.995, 1.005) ! 2,
                Rand(0, 1),
                Rand(0, 1),
                0.3
            )
        ]) * 0.15 * aEnv * amp;
        sig = BLowPass.ar(sig, 0.3e3 + (In.kr(~sweep) * 1), 0.3);
        sig = Compander.ar(sig, In.ar(~sidechain, 2) * 6, 0.1, 1, 1/4, 0.01, 0.1);
        Out.ar(~chorus, sig);
    }).add;

    SynthDef(\fm_stab, {
        arg freq = 500, amp = 0.1, attack = 0.1, release = 0.1, detune = 0.5;
        // Create array of modulation frequency partials and modulations indexes
        var partials = [ 1 + detune, 2 + detune, 4 + detune, 12 + detune ];
        var indexes = [ 1, 2, 4, 8 ];
        var ampEnv = EnvGen.ar(Env.perc(attack, release), doneAction: 2);
        var freqEnv = freq + (EnvGen.ar(Env.perc(0.01, 0.1)) * 4e3);
        // Create carrier oscillator and modulate the frequency with a sum of modulators
        var sig = SinOsc.ar(freq + Mix(partials.size.collect {
            arg n;
            var modfreq = freq * partials[n] * Rand(0.9999, 1.0001) ! 2;
            SinOsc.ar(modfreq, 0, modfreq*indexes[n]);
            // Phase is modulated by a Saw oscillator
        }), Saw.kr(3).range(-2pi, 2pi));
        sig = sig * amp * ampEnv * 0.3;
        // Apply band-pass filter to attenuate high frequency content
        sig = BBandPass.ar(sig, freqEnv, 1.5);
        Out.ar(~chorus, sig * 0.1);
        Out.ar(0, sig * 0.5);
    }).add;

    SynthDef(\bell, {
        arg gate=1, freq=100, decay=0.6, amp=1, reverb = 0.05, distort = 1, delay = 0.5;
        var excitation, sig, aEnv, fEnv;
        excitation = WhiteNoise.ar(EnvGen.ar(Env.perc(1e-6, 0.01)));
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
        sig = (sig+excitation) * 0.2 * amp;
        sig = (sig * (1-distort)) + ((sig * distort.linexp(0, 1, 1, 100)).distort * distort.linexp(0, 1, 1, 0.02));
        Out.ar(0, sig ! 2);
        Out.ar(~reverb, sig*reverb ! 2);
        Out.ar(~delay, sig*delay ! 2);
    }).add;


    SynthDef(\sweep_control, {
        arg cutoff = 0, lag_time = 0.5;
        Out.kr(~sweep, Lag.kr(cutoff, lag_time));
    }).add;
});
)