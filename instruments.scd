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
	var aEnv = EnvGen.kr(Env.perc(attack, release),doneAction: 2);
	var sig = WhiteNoise.ar * aEnv* amp;
	sig = RHPF.ar(sig, freq,0.2);
	Out.ar(0, sig ! 2)
}).add;

SynthDef(\tone, {
	arg amp = 0.1, attack = 0.01, release = 0.5, freq = 220, dist = 100;
	var aEnv = EnvGen.kr(Env.perc(attack, release),doneAction: 2);
	var sig = Saw.ar([freq*1.01,freq*0.99]);
	sig = BPF.ar(sig,freq,0.2) *amp * aEnv;

	/* ---------Effects-------------- */

	//Distortion
	sig = (dist) * sig / (1 + (dist * sig.abs));

	Out.ar(0,sig);
}).add;

)