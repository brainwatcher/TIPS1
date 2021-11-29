function Ts = tryOnetime(U,ER0,EC0,areaR,areaC,method_ROI,method_Cortex)
D0_ROI = Onetime(ER0,U);
D_ROI = tryOnetimeMethod(D0_ROI,areaR,method_ROI);
D0_Cortex = Onetime(EC0,U);
D_Cortex = tryOnetimeMethod(D0_Cortex,areaC,method_Cortex);
R = D_ROI/D_Cortex;
tableName = {'R';'ROI';'Cortex'};
Ts = table(R,D_ROI,D_Cortex,'VariableNames',tableName);
end


