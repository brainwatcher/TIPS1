function Kc = getKcCortex(N,maxKc)
%GETKCCORTEX �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
coef = 0.5;
g = gpuDevice(1);
Kc0 = round(g.AvailableMemory/4/N*coef);
Kc = min([Kc0,maxKc]);
Kc = int32(Kc);
end

