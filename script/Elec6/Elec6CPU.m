function [Fc] = Elec6CPU(E0,elecAFix,elecBFix,C,beta,area,method)
%MORE2ABCPU Summary of this function goes here
%   Detailed explanation goes here
Fc = zeros(size(beta,1),size(C,1));
for j = 1:size(C,1)
    for i = 1:size(beta,1)
    Ea = beta(i,1)*E0(:,:,elecAFix(1))+beta(i,2)*E0(:,:,elecAFix(2))+beta(i,3)*E0(:,:,C(j,1));
    Eb = beta(i,4)*E0(:,:,elecBFix(1))+beta(i,5)*E0(:,:,elecBFix(2))+beta(i,6)*E0(:,:,C(j,2));
    rc = basic2(Ea,Eb);
    Fc(i,j) = tryOnetimeMethod(rc,area,method);
    end
end
end

