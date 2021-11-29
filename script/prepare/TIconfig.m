function cfg = TIconfig(dataRoot,subMark,simMark)
%TICONFIG Summary of this function goes here
%   Detailed explanation goes here
simDir = fullfile(dataRoot,subMark,'TI_sim_result',simMark);
if ~exist(simDir,'dir')
    mkdir(simDir);
end
%% build simulation config here
%% ROI tri
cfg.type = 'tri';
cfg.ROI.type = 'atlas';% atlas, coord
cfg.ROI.atlas = 'DK40';
cfg.ROI.name = 'lh.insula';
%% ROI tet
% cfg.type = 'tet';
% cfg.ROI.type = 'atlas';
% cfg.ROI.atlas = 'AAL3';
% cfg.ROI.label = 33;
% cfg.ROI.matter = 2; %1 white 2 gray
% ROI.name = 'lh.caudalanteriorcingulate';
%% nt
cfg.nt = 0;
%% penalty
cfg.P = 0;
% P.type = 'atlas';% atlas, coord
% P.atlas = 'DK40';
% P.name = 'lh.caudalanteriorcingulate';
%% method
cfg.method_ROI = 0;
cfg.method_Other = 0;
%% thres
cfg.thres = 0.2;
%%
%% save
save(fullfile(simDir,'cfg.mat'),'cfg');
end

