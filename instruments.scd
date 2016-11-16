(
SynthDef(\bd, {
    arg amp = 0.1, startFreq = 150, endFreq = 50, freqEnvTime = 0.05, release = 0.1;
    var aEnv = EnvGen.kr(Env.perc(1e-3, release), doneAction: 2);
    var sig = SinOsc.ar(XLine.kr(startFreq, endFreq, freqEnvTime)) * aEnv * amp;
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\sd, {
    arg amp = 0.1, release = 0.02;
    var aEnv = EnvGen.kr(Env.perc(1e-3, release), doneAction: 2);
    var sig = WhiteNoise.ar * aEnv * amp;
    sig = sig + (SinOsc.ar(300, 0, 0.5) * aEnv);
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\hat,{
	arg amp = 0.1, attack = 1e-3, release = 0.1, freq = 1000;
	var aEnv = EnvGen.kr(Env.perc(attack, release, 1, -8),doneAction: 2);
	var sig = WhiteNoise.ar * aEnv* amp;
	sig = RHPF.ar(sig, freq,0.7);
	Out.ar(0, sig ! 2)
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



SynthDef(\cymbal, {
	// Cymbal sound made with resonatorbanks of fixed exponentially distributed frequencies.
	arg release = 10, amp = 1;
	var lodriver, locutoffenv, hidriver, hicutoffenv, freqs, sig;

	//
	var ampEnv = EnvGen.ar(Env.perc(0,0.1));
	var freqEnv = EnvGen.ar(Env.perc(0,0.4))*15e3;
    var excitation = Klank.ar(`[{exprand(300, 20000)}.dup(100), nil, { 0.3 }.dup(100)], Impulse.ar(0.1)) * 1/100;
	excitation = BLowPass4.ar(excitation ,freqEnv+500, 0.4)*ampEnv;

	// Driver for low frequencies to resonatorbank,
	locutoffenv = EnvGen.ar(Env.perc(0.5, release)) * 20000 + 100;
	lodriver = LPF.ar(WhiteNoise.ar(0.1), locutoffenv);

	//Driver for high frequencies to resonatorbank + amplitude attenuation
    hicutoffenv = XLine.kr(50,4e3, 0.2);
	hidriver = BHiPass4.ar(WhiteNoise.ar(0.1), hicutoffenv, 2);
	hidriver = hidriver * EnvGen.ar(Env.perc(1, 2, release/10)) * 3;

	//Exponential frequency distribution
	freqs  = {exprand(300, 20000)}.dup(200);
    sig = Klank.ar(`[freqs, nil, { 2 }.dup(200)], lodriver + hidriver + excitation) * 1/200;

	// The hit is added to signal, together with some of the low driving noise
    sig = ((sig * 1) + (lodriver * 2) + (excitation * 2)).dup;
    sig = sig *EnvGen.ar(Env.perc(1e-3, release, 1, -32), doneAction: 2);

	Out.ar(0, sig*0.5*amp);
}).add;

SynthDef(\ride,{
	arg release = 1, amp = 0.5;
	var ampEnv = EnvGen.ar(Env.perc(0,release, 1, -8),doneAction: 2);
	var freqEnv = EnvGen.ar(Env.perc(0,release*0.8))*20000;
	var sig = Klank.ar(`[{exprand(500, 20000)}.dup(100), nil, { release }.dup(100)], Impulse.ar(0.1)) * 1/100;
	sig = LPF.ar(sig,freqEnv+500);
	sig = sig * ampEnv;

	Out.ar(0, (sig*amp) ! 2);
}).add;


SynthDef(\fm_stab, {
	arg freq = 100, amp = 0.1, attack = 0.1, release = 0.5, detune = 0.5;
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
	arg gate=1, freq=100, decay=0.6, amp=1;
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
	aEnv = EnvGen.ar(Env.perc(0.0000000001,decay),doneAction: 2);
	Out.ar(0, Pan2.ar((sig+excitation) * amp));
}).add;


)
