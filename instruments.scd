(
SynthDef(\bd, {
    arg amp;
    var aEnv = EnvGen.kr(Env.perc(1e-3, 0.1));
    var sig = SinOsc.ar(XLine.kr(150, 50, 0.05)) * aEnv * amp;
    Out.ar(0, sig ! 2);
}).add;
)