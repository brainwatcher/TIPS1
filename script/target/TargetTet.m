function [ROI_idx] = TargetTet(dataRoot,subMark,mesh,cfg)
DT = mesh.DT;
elem5 = mesh.elem5;
%% ROI_node_idx
m2mPath = fullfile(dataRoot,subMark, ['m2m_' subMark]);
switch cfg.ROI.type
    case 'atlas'
        switch cfg.ROI.atlas
            case 'AAL3'
                ROI_coord_MNI = AAL3ROI(cfg.ROI.label);
            otherwise
                error('No coresponding atlas for tetrahedron!');
        end
        disp(['Define ROI using atlas ' cfg.ROI.atlas '...']);
    case 'coord'
        disp('Define ROI using MNI coordinates ... ');
        if size(cfg.ROI.coord_MNI,2)==3
            ROI_coord_MNI = cfg.ROI.coord_MNI;
        end
    otherwise
        error('Wrong ROI type define!');
end
coord_sub = mni2subject_coords(ROI_coord_MNI, m2mPath);%坐标转换
%%
elem_label = (1:size(DT))';
elem_idx = ismember(elem5,cfg.ROI.matter);
elem1 = DT.ConnectivityList(elem_idx,:);
elem1_label = elem_label(elem_idx);
%%
DT1 = simpleTR(triangulation(elem1,DT.Points));
ID1 = pointLocation(DT1,coord_sub);
ID1 = ID1(~isnan(ID1));
ID1_u = unique(ID1);
ROI_idx = false(size(DT,1),1);
ROI_idx(elem1_label(ID1_u)) = true;
end

