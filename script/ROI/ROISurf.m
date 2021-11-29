function [ROI_node_idx] = ROISurf(dataRoot,subMark,gmS,cfgROI)
%% ROI_node_idx
m2mPath = fullfile(dataRoot,subMark, ['m2m_' subMark]);
switch cfgROI.type
    case 'atlas'
        disp(['Define ROI using atlas ' cfg.ROI.atlas '...']);
        [labels, snames] = subject_atlas(gmS, m2mPath, cfg.ROI.atlas);
        ROI_idx = find(strcmpi(snames, cfg.ROI.name));
        if isempty(ROI_idx)
            error('No corresponding ROI name for this atlas!');
        else
            ROI_node_idx = labels.node_data{1}.data == ROI_idx;
        end
    case 'coord'
        disp('Define ROI using MNI coordinates ... ');
        coord_sub = mni2subject_coords(cfg.ROI.coord_MNI, m2mPath);%坐标转换
        ROI_node_idx = unique(dsearchn(gmS.nodes,coord_sub));
    otherwise
        error('Wrong ROI type!');
end

end

