function TB = CortexTable(T1,B)
%CORTEXTABLE 此处显示有关此函数的摘要
%   此处显示详细说明
tableName = {'elec';'cu';'R';'ROI';'Cortex'};
R = T1.ROI./B;
TB0 = table(T1.elec,T1.cu,R,T1.ROI,B,'VariableNames',tableName);
TB = sortrows(TB0,3,'d');
end

