function B = Cortex_nt_Wrapper(N,E0,T,area,method)
%% N,beta,method
N = int32(N);
method = int32(method);
vflag = true;
%%
blockSize = int32(128);
Kc0 = getKcCortex(N,size(T,1));
Kc = Kc0*blockSize;
B = Cortex_nt(N,E0,T.elec,T.cu,area,Kc,method,vflag,blockSize);
end

