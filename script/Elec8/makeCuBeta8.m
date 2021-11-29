function [cu] = makeCuBeta8(lb,U)
%MAKECUBETA Summary of this function goes here
%   Detailed explanation goes here
cuMax = 2; % 2mA
step = 0.05; % minimal current step
cuFreeMax = (1-lb)*cuMax;
cuFree = step:step:cuFreeMax;
cu1 = cell(length(cuFree),1);
for i = 1:length(cuFree)
    r = fix(cuFree(i)/step);
    ratio = (cuMax-cuFree(i))/cuMax;
    cu0 = cell(r+1,1);
    for j = 0:r
        ra = r-j;
        rb = j;
        cua = arrangeCu(U.a,ra,step,ratio);
        cub = arrangeCu(U.b,rb,step,ratio);
        % full factor
        cu0{j+1} = [repmat(cua,size(cub,1),1),repelem(cub,size(cua,1),1)];
    end
    cu1{i} = vertcat(cu0{:});
end
cu = vertcat(cu1{:});
end
function cu = arrangeCu(U,r,step,ratio)
idx_cu_p = U.cu>0;
idx_cu_n = ~idx_cu_p;
if r~=0
%% r > 0
switch sum(idx_cu_n)
    case 2
        cuP = repmat([U.cu'*ratio,r*step],r+1,1);
        tmp = (0:r)'*step;
        cu_add = -[tmp,r*step-tmp];
        cuP(:,idx_cu_n) = cuP(:,idx_cu_n)+cu_add;
    case 1 
        cuP = [U.cu'*ratio,r*step];
        cu_add = -r*step;
        cuP(idx_cu_n) = cuP(idx_cu_n)+cu_add;
end
switch sum(idx_cu_p)
    case 2
        cuN = repmat([U.cu'*ratio,-r*step],int32(r+1),1);
        tmp = (0:r)'*step;
        cu_add = [tmp,r*step-tmp];
        cuN(:,idx_cu_p) = cuN(:,idx_cu_p)+cu_add;
    case 1 
        cuN = [U.cu'*ratio,-r*step];
        cu_add = r*step;
        cuN(idx_cu_p) = cuN(idx_cu_p)+cu_add;
end
cu = [cuP;cuN];
else 
  cu =   [U.cu'*ratio,r];
end


end

