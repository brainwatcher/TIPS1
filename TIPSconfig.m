%% path
cfg.dataRoot = 'C:\Users\psylab706\Documents\simnibs_examples';
cfg.subMark = '001';
cfg.simMark = 'test import';
%% element type
cfg.type = 'tet';
%% orientation options
cfg.ntGM = false;
cfg.ntWM = false;
%% table
varTypes = ["string","double","double"];
varNames = ["Name","CoordMNI","Radius"];
%% ROI
cfg.ROI.num = 1;
cfg.ROI.table = table('Size',[cfg.ROI.num,3],'VariableTypes',varTypes,'VariableNames',varNames);
cfg.ROI.table.Name = ['dACC'];
cfg.ROI.table.CoordMNI = [1 18 39];
cfg.ROI.table.Radius = 5;
%% Penalty
cfg.Penalty.num = 2;
cfg.Penalty.table = table('Size',[cfg.Penalty.num,3],'VariableTypes',varTypes,'VariableNames',varNames);
cfg.Penalty.table.Name = ['l.dlPFC';'r.dlPFC'];
cfg.Penalty.table.CoordMNI = [-44 6 33;43 9 30];
cfg.Penalty.table.Radius = [30,30]';
%% other coefficients
cfg.elecNum = 4;
cfg.elecCandNum = 20;
cfg.thres = 0.2; % unit V/m
cfg.Penalty.coef = 2;
cfg.method_ROI = 0;
cfg.method_Other = 2;
%% save
simDir = fullfile(cfg.dataRoot,cfg.subMark,'TI_sim_result',cfg.simMark);
if ~exist(simDir,'dir')
    mkdir(simDir);
end
save(fullfile(simDir,'cfg.mat'),'cfg');

