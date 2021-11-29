function T_Cortex = ROIScreen(A_ROI,C,cu1,thres)
%ROISCREEN Summary of this function goes here
%   Detailed explanation goes here
idx = find(A_ROI>thres);
[i,j] = ind2sub(size(A_ROI),idx);
tableName = {'elec';'cu';'ROI'};
T_Cortex = table(C(j,:),single(cu1(i)),A_ROI(idx),'VariableNames',tableName);
end

