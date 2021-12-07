function h = plotClip(dataRoot,subMark,cfg,U,Eam_Ub,clipStr)
%PLOTCLIP Summary of this function goes here
%   Detailed explanation goes here
%% prepare
cfg.type = 'tet';
[Data_tet,m_tet] = prepare_LF(dataRoot,subMark,cfg);
%% Out contour
[node,~,simNIBS_face] = MeshfromSimnibs(dataRoot,subMark);
csfMark = 1003;
face_out = double(simNIBS_face(simNIBS_face(:,4)==csfMark,1:3));
TR_out = simpleTR(triangulation(face_out,node));
%% ROI contour
ROI_idx = TargetRegionIdx(dataRoot,subMark,m_tet,cfg.ROI,cfg.type);
DT_ROI = simpleTR(triangulation(m_tet.DT.ConnectivityList(ROI_idx,:),m_tet.DT.Points));
face_ROI = getSurf(DT_ROI.ConnectivityList);
TR_ROI = simpleTR(triangulation(face_ROI,DT_ROI.Points));
%% Penalty contour
if isfield(cfg,'Penalty')
    Penalty_idx = TargetRegionIdx(dataRoot,subMark,m_tet,cfg.Penalty,cfg.type);
    DT_Penalty = simpleTR(triangulation(m_tet.DT.ConnectivityList(Penalty_idx,:),m_tet.DT.Points));
    face_Penalty = getSurf(DT_Penalty.ConnectivityList);
    TR_Penalty = simpleTR(triangulation(face_Penalty,DT_Penalty.Points));
end
%% clip section interpolation
Eam = Onetime(Data_tet.E,U);
%%
for i = 1:length(clipStr)
    %%
    EV_out = SurfCrossSection(TR_out,clipStr{i},node);
    EV_ROI = SurfCrossSection(TR_ROI,clipStr{i},node);
    if isfield(cfg,'Penalty')
        EV_Penalty = SurfCrossSection(TR_Penalty,clipStr{i},node);
    end
    %%
    [TR_section,eIdx] = TetCrossSection(m_tet.DT,clipStr{i});
    Eam_norm = vecnorm(Eam(eIdx,:),2,2);
    [~,~,dof] = str2XYZ(clipStr{i});
    %%
    h = maxfigwin();
    axis equal;
    h = plotCrossSection(h,TR_section,Eam_norm,Eam_Ub);
    hold on;
    %% plot ROI contour (all the contours)
    if ~isempty(EV_ROI.Edge)
        for j = 1:length(EV_ROI.Edge)
            h = plotContour(h,EV_ROI.Points,EV_ROI.Edge{j},dof,'k-','LineWidth',2);
        end
    else
        disp('No ROI in this clipped section!!!');
    end
    %% plot Penalty contour (all the contours)
    if isfield(cfg,'Penalty')
        if ~isempty(EV_Penalty.Edge)
            for j = 1:length(EV_Penalty.Edge)
                h = plotContour(h,EV_Penalty.Points,EV_Penalty.Edge{j},dof,'k-','LineWidth',2);
            end
        else
            disp('No Penalty in this clipped section!!!');
        end
    end
    %% plot out contour (only the longest contour)
    h = plotContour(h,EV_out.Points,EV_out.Edge{1},dof,'k-','LineWidth',5);
    axis off;
    %%
    title(clipStr{i});
end
end

