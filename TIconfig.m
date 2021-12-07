function cfg = TIconfig(dataRoot,subMark,simMark)
%TICONFIG Summary of this function goes here
%   Detailed explanation goes here
simDir = fullfile(dataRoot,subMark,'TI_sim_result',simMark);
if ~exist(simDir,'dir')
    mkdir(simDir);
end
%% build simulation config here
%% element type
cfg.type = 'tet';
%%　tri ROI
% cfg.ROI.type = 'atlas';% atlas, coord
% cfg.ROI.atlas = 'DK40';
% cfg.ROI.name{1} = 'lh.insula';
cfg.ROI.num = 1;
cfg.ROI.type = 'coord';% atlas, coord
cfg.ROI.center = [1 18 39]; % need to input ACC MNI XYZ
cfg.ROI.r = 5;
%% tri penalty
% Penalty.type = 'atlas';% atlas, coord
% Penalty.atlas = 'DK40';
% Penalty.name = 'lh.caudalanteriorcingulate';
% cfg.Penalty.type = 'coord';% atlas, coord
cfg.Penalty.num = 2;
cfg.Penalty.coef = 2;
cfg.Penalty.center = [-44 6 33;43 9 30]; % need to input DLPFC MNI XYZ
cfg.Penalty.r = [30,30];

%%  tet
% cfg.type = 'tet';
% cfg.ROI.type = 'atlas';
% cfg.ROI.atlas = 'AAL3';
% cfg.ROI.label = 33;
% cfg.ROI.matter = 2; %1 white 2 gray
% ROI.name = 'lh.caudalanteriorcingulate';
%% nt
cfg.nt = 0;
%% method
cfg.method_ROI = 0;
cfg.method_Other = 2;
%% thres
cfg.thres = 0.2;
%%
%% save
save(fullfile(simDir,'cfg.mat'),'cfg');
end

