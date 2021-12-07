dataRoot = 'E:\Ginger\simnibs_examples';%被试数据根目录
subMark = 'ernie';
simMark = 'ACC_r5_mO2_mR0_P2_r30';
workSpace = fullfile(dataRoot,subMark,'TI_sim_result',simMark);
%% load U
S = load(fullfile(workSpace,'elec4.mat'));
disp(S.T4m);
showU(S.U4m);
%% plot elec in 10-10 system
grayMark = 0;
h = plotElec1010(S.U4m,S.electrodes,grayMark);

