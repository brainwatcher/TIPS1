function Kc = getKcElec8(N,Ku,maxKc,blockSize)
%GETKCB Summary of this function goes here
%   Detailed explanation goes here
coef = 0.5;
g = gpuDevice(1);
Kc0 = round(g.AvailableMemory/4/(N*Ku) *coef*blockSize);
Kc = min([Kc0,maxKc]);
Kc = int32(Kc);
end

