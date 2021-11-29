function [D0] = Onetime(E0,U)
[Ea,Eb] = proE(E0,U);
D0 = basic2(Ea,Eb);
end