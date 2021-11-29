function TB = CortexTable(T1,B)
%CORTEXTABLE �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
tableName = {'elec';'cu';'R';'ROI';'Cortex'};
R = T1.ROI./B;
TB0 = table(T1.elec,T1.cu,R,T1.ROI,B,'VariableNames',tableName);
TB = sortrows(TB0,3,'d');
end

