dataRoot = 'C:\Users\psylab706\Documents\simnibs_examples';
subMark = 'ernie';
simMark = 'test_tri';
workSpace = fullfile(dataRoot,subMark,'TI_sim_result',simMark);
%% load U
S = load(fullfile(workSpace,'elec4.mat'));
clipStr = 'z=50';
Eam_Ub = 0.4;
%% load cfg in tet
load(fullfile(workSpace,'cfg.mat'));
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
[TR_section,eIdx] = TetCrossSection(mesh_tet.DT,clipStr);
Eam_norm = vecnorm(Eam(eIdx,:),2,2);
[XYZmark,XYZvalue,dof] = str2XYZ(clipStr);
%%
h = figure;
axis equal;
h = plotCrossSection(h,TR_section,Eam_norm,Eam_Ub);
hold on;
if ~isempty(EV_ROI.Edge)
    h = plotContour(h,EV_ROI,dof,'k-','LineWidth',2);
else
    disp('No ROI in this clipped section!!!');
end
h = plotContour(h,EV_out,dof,'k-','LineWidth',5);
axis off;