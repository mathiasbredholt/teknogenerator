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
    sig = sig + (SinOsc.ar(500) * aEnv);
    Out.ar(0, sig ! 2);
}).add;
)