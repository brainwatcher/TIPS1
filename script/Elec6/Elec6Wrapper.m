function Fg = Elec6Wrapper(N,E0,area,method,cu,C,U)
%MODIFYWRAPPER Summary of this function goes here
%% cu
% at least remain 75% I 
cu = single(cu);
%% C0
C0 = int32(C);
elecAFix = int32(U.a.elec);
elecBFix = int32(U.b.elec);
%%
method = int32(method);
N = int32(N);
elecAFix = int32(elecAFix);
elecBFix = int32(elecBFix);
vflag = false;
blockSize = int32(64);
Kc = getKcElec6(N,size(cu,1),size(C0,1),blockSize);
[Fg0] = Elec6(N,E0,elecAFix,elecBFix,C0,cu,area,method,Kc,vflag,blockSize);
Fg = reshape(Fg0,size(C0,1),[])';
%%  CPU check
% [Fc] = More2ABCPU(E0,elecAFix,elecBFix,C0(1:5,:),cu,area,method);
% disp(max(max(abs(Fg(:,1:5)-Fc))));
end

