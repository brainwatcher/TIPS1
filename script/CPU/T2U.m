function U = T2U(T)
elec_a = T.elec(1:2);
elec_b = T.elec(3:4);
cu_a = T.cu;
cu_b = 2-cu_a;
U.a = t2u(elec_a,cu_a);
U.b = t2u(elec_b,cu_b);  
end
function U = t2u(elec,cu)
cu = [cu;-cu];
elec = elec(:);
tableName = {'elec';'cu'};
U = table(elec,cu,'VariableNames',tableName);
end
