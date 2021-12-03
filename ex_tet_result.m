dataRoot = 'C:\Users\psylab706\Documents\simnibs_examples';
subMark = 'ernie';
simMark = 'test_tri';
workSpace = fullfile(dataRoot,subMark,'TI_sim_result',simMark);
%% load U
S = load(fullfile(workSpace,'elec4.mat'));
clipStr = 'z=33';
Eam_Thres = 0.4;
%% load Data_tet
cfg_tet.type = 'tet';
[Data_tet,mesh_tet] = prepare_LF(dataRoot,subMark,cfg_tet);
%% input U
Eam = Onetime(Data_tet.E,S.U4m);
%% clip
[TR,eIdx] = TetCrossSection(mesh_tet.DT,clipStr);
Eam_norm = vecnorm(Eam(eIdx,:),2,2);
[XYZmark,XYZvalue,dof] = str2XYZ(clipStr);
%% surf intersection 
couterMark = [1003];
[EV,p0,p1] = SurfCrossSection(dataRoot,subMark,clipStr,couterMark);
%% ROI contour
% TODO
%%
h = figure;
axis equal;
h = plotCrossSection(h,TR,Eam_norm,Eam_Thres);
hold on;
h = plotContour(h,EV,dof,'k-','LineWidth',5);
axis off;