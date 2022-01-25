function [S,h1,h2] = openTIPS_plot(cfg)

resultDir = fullfile(cfg.dataRoot,cfg.subMark,'TI_sim_result',cfg.simMark);
S = load(fullfile(resultDir,'elec4.mat'));
%% electrode map
h1 = plotElec1010(S.Um,S.electrodes,0);
%% plot clip figure in X,Y,Z
Eam_Ub = 0.2;
clipStr = clipStrFromCenter(cfg.dataRoot,cfg.subMark,cfg.ROI.table.CoordMNI); % define clipStr from ROI center
disp(clipStr);
h2 = plotClip(cfg.dataRoot,cfg.subMark,cfg,S.Um,Eam_Ub,clipStr);
