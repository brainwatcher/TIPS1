function [target_node_idx] = TargetRegionIdx(dataRoot,subMark,mesh,cfgTarget,cfgType)
switch cfgType
    case 'tri'
        target_node_idx = TargetSurf(dataRoot,subMark,mesh,cfgTarget);
    case 'tet'
        target_node_idx = TargetTet(dataRoot,subMark,mesh,cfgTarget);
end
end

