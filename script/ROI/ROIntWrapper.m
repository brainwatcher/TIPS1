function [A_ROI,C0] = ROI_nt_Wrapper(N,E0,c0,beta,area,method)
%% C0
C0 = int32(zeros(size(c0,1)*3,size(c0,2)));
c_seq = [1,2,3,4;1,3,2,4;1,4,2,3];
Nc = size(c0,1);
for i = 1:3
    idx = ((i-1)*Nc+1):i*Nc;
    C0(idx,:) = c0(:,c_seq(i,:));
end
%% N,beta,method
N = int32(N);
beta = single(beta);
method = int32(method);
%% Kc : could be user defined
blockSize = int32(64);
Kc = getKcROI(size(E0,1),length(beta),size(C0,1),blockSize);
%% vflag
vflag = true;
%% if 
if length(size(E0))==3
    a = ROInt_cuda(N,E0,C0,beta,method,Kc,vflag,area,blockSize);
    A_ROI = reshape(a,size(C0,1),[])';
end

