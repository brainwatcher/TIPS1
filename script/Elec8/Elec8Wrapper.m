function Fg = Elec8Wrapper(N,E0,area,method,cu,C,U)
%MODIFYWRAPPER Summary of this function goes here
%% cu
% at least remain 75% I 
cu = single(cu);
%% C0
C0 = int32(C);
%%
method = int32(method);
N = int32(N);
elecAFix = int32(U.a.elec);
elecBFix = int32(U.b.elec);
vflag = false;
blockSize = int32(64);
Kcu = int32(200);
Kc = getKcElec8(N,Kcu,size(C0,1),blockSize);
[Fg0] = Elec8(N,E0,elecAFix,elecBFix,C0,Kc,cu',Kcu,area,method,vflag,blockSize);
Fg = reshape(Fg0,size(C0,1),[])';
% figure;spy(sparse(double(Fg)));
%% check
% Kc = int32(1000);
% Kcu = int32(50);
% [Fgb0] = Elec8(N,E0,elecAFix,elecBFix,C0,Kc,cu',Kcu,area,method,vflag,blockSize);
% Fgb = reshape(Fgb0,size(C0,1),[])';
% figure;spy(sparse(double(Fgb)));
% M = abs(Fg-Fgb);
% figure;spy(sparse(double(M)));
% disp(max(max(M)));
% [Fc] = Elec8CPU(E0,elecAFix,elecBFix,C0(1:5,:),cu(1:5,:),area,method);
% disp(max(max(abs(Fg(1:5,1:5)-Fc))));
end

