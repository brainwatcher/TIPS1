function [E1,N] = zeroPadding(E0,p)
%ZEROPADDING �˴���ʾ�йش˺�����ժҪ
N = size(E0,1);
Np = p-mod(N,p);
if Np<p
Ep = single(zeros([Np,size(E0,[2,3])]));
E1 = [E0;Ep];
else
    E1 = E0;
end
end

