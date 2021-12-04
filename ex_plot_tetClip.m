dataRoot = 'C:\Users\psylab706\Documents\simnibs_examples';
% dataRoot = 'E:\MyLabFiles\TI_Simulation';
subMark = 'ernie';
simMark = 'test_tet_ACC_noPenalty_r5_mO2';
workSpace = fullfile(dataRoot,subMark,'TI_sim_result',simMark);
%% load U
Eam_Ub = 0.25;
XYZmark  = 1;
S = load(fullfile(workSpace,'elec4.mat'));
load(fullfile(workSpace,'cfg.mat'));
%% predefine clipStr
% clipStr = 'x=5'; % in sub space
%%  Or get clipStr from ROI center
m2mPath = fullfile(dataRoot,subMark, ['m2m_' subMark]);
center_sub = mni2subject_coords(cfg.ROI.center, m2mPath);
switch XYZmark
    case 1
        clipStr = ['x=' num2str(round(center_sub(XYZmark)))];
    case 2
        clipStr = ['y=' num2str(round(center_sub(XYZmark)))];
    case 3
        clipStr = ['z=' num2str(round(center_sub(XYZmark)))];
end

%%
cfg.type = 'tet';
[Data_tet,m_tet] = prepare_LF(dataRoot,subMark,cfg);
%% Out contour
[node,~,simNIBS_face] = MeshfromSimnibs(dataRoot,subMark);
csfMark = 1003;
face_out = double(simNIBS_face(simNIBS_face(:,4)==csfMark,1:3));
TR_out = simpleTR(triangulation(face_out,node));
EV_out = SurfCrossSection(TR_out,clipStr,node);
%% ROI contour
ROI_idx = TargetRegionIdx(dataRoot,subMark,m_tet,cfg.ROI,cfg.type);
DT_ROI = simpleTR(triangulation(m_tet.DT.ConnectivityList(ROI_idx,:),m_tet.DT.Points));
face_ROI = getSurf(DT_ROI.ConnectivityList);
TR_ROI = simpleTR(triangulation(face_ROI,DT_ROI.Points));
EV_ROI = SurfCrossSection(TR_ROI,clipStr,node);
%% clip section interpolation
Eam = Onetime(Data_tet.E,S.U4m);
[TR_section,eIdx] = TetCrossSection(m_tet.DT,clipStr);
Eam_norm = vecnorm(Eam(eIdx,:),2,2);
[XYZmark,XYZvalue,dof] = str2XYZ(clipStr);
%%
h = figure;
axis equal;
h = plotCrossSection(h,TR_section,Eam_norm,Eam_Ub);
hold on;
%% plot ROI contour (all the contours)
if ~isempty(EV_ROI.Edge)
    for i = 1:length(EV_ROI.Edge)
        h = plotContour(h,EV_ROI.Points,EV_ROI.Edge{i},dof,'k-','LineWidth',2);
    end
else
    disp('No ROI in this clipped section!!!');
end
%% plot out contour (only the longest contour)
h = plotContour(h,EV_out.Points,EV_out.Edge{1},dof,'k-','LineWidth',5);
axis off;
%%
title(clipStr);