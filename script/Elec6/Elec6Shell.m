function [T,U] = Elec6Shell(Nr,ER0P,areaRP,Nc,EC0P,areaCP,method_ROI,method_Cortex,cu,C,U,thres,Rthres,kMax)
%MODIFY4S Summary of this function goes here
%   Detailed explanation goes here
FC = Elec6Wrapper(Nc,EC0P,areaCP,method_Cortex,cu,C,U);
FR = Elec6Wrapper(Nr,ER0P,areaRP,method_ROI,cu,C,U);
FR(FR<=thres) = 0;
FP = FR./FC;
FP(FP<=Rthres) = 0;
idx0 = find(FP);
tableName = {'R';'ROI';'Cortex'};
T0 = table(FP(idx0),FR(idx0),FC(idx0),'VariableNames',tableName);
if size(T0,1)>kMax
    [~,is] = sortrows(T0,1,'d');
    idx = idx0(is(1:kMax));
    T = T0(is(1:kMax),:);
else
    idx = idx0;
    T = T0;
end
%%
[i,j] = ind2sub(size(FP),idx);
elecAFix = int32(U.a.elec);
elecBFix = int32(U.b.elec);
U = cell(length(idx),1);
tableName = {'elec';'cu'};
for k = 1:length(idx)
elec_a = [elecAFix;C(j(k),1)];
elec_b = [elecBFix;C(j(k),2)];
cu_a = cu(i(k),1:3);
cu_b = cu(i(k),4:6);
U{k}.a = table(elec_a(:),cu_a(:),'VariableNames',tableName);
U{k}.b = table(elec_b(:),cu_b(:),'VariableNames',tableName);
U{k}.a = sortrows(U{k}.a,2,'d');
U{k}.b = sortrows(U{k}.b,2,'d');
end



