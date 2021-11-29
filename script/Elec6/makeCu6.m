function cu6 = makeCu6(lb,U)
%MAKECUBETA Summary of this function goes here
%   Detailed explanation goes here
cuMax = 2; % 2mA
step = 0.05; % minimal current step
cuFreeMax = (1-lb)*cuMax;
cuFree = step:step:cuFreeMax;
cuA = cell(length(cuFree),1);
cuB = cell(length(cuFree),1);
for i = 1:length(cuFree)
    ratio = (cuMax-cuFree(i))/cuMax;
    %% A
    cuA_add0 = (0:step:cuFree(i))';
    cuA_add1 = [cuA_add0;cuA_add0;-cuA_add0;-cuA_add0];
    cuA_remain = repmat((U.a.cu(:).*ratio)',size(cuA_add1,1),1);
    idx = cuA_add1>0;
    cuA_remain(idx,2) = cuA_remain(idx,2)-cuA_add1(idx);
    cuA_remain(~idx,1) = cuA_remain(~idx,1)-cuA_add1(~idx);
    cuA{i} = [cuA_remain,cuA_add1];
    %% B
    cuB_add0 = cuFree(i)-cuA_add0;
    cuB_add1 = [cuB_add0;-cuB_add0;cuB_add0;-cuB_add0];
    cuB_remain = repmat((U.b.cu(:).*ratio)',size(cuB_add1,1),1);
    idx = cuB_add1>0;
    cuB_remain(idx,2) = cuB_remain(idx,2)-cuB_add1(idx);
    cuB_remain(~idx,1) = cuB_remain(~idx,1)-cuB_add1(~idx);
    cuB{i} = [cuB_remain,cuB_add1];
end
betaA = vertcat(cuA{:});
betaB = vertcat(cuB{:});
cu6 = [betaA,betaB];

