dataRoot = 'C:\Users\psylab706\Documents\simnibs_examples';%被试数据根目录
subMark = 'ernie';
simMark = 'test_tri';
workSpace = fullfile(dataRoot,subMark,'TI_sim_result',simMark);
%% load U
load(fullfile(workSpace,'elec4.mat'));
disp(T4m);
showU(U4m);
%% plot elec in 10-10 system
grayMark = 0;
h = plotElec1010(U4m,Data.electrodes,grayMark);

