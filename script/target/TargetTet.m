function target_node_idx_all = TargetTet(dataRoot,subMark,mesh,cfgTarget)
%% ROI_node_idx
m2mPath = fullfile(dataRoot,subMark, ['m2m_' subMark]);
% switch cfgTarget.type
%     case 'atlas'
%         disp(['Define target using atlas ' cfgTarget.atlas '...']);
%         switch cfgTarget.atlas
%             case 'AAL3'
%                 target_coord_MNI = AAL3ROI(cfgTarget.label);
%             otherwise
%                 error('No coresponding atlas for tetrahedron!');
%         end
%         disp(['Define ROI using atlas ' cfg.ROI.atlas '...']);
%     case 'coord'
%         disp('Define ROI using MNI coordinates ... ');
%         if size(cfgTarget.center,2)==3
%             target_coord_MNI = cfgTarget.center;
%         end
%     otherwise
%         error('Wrong ROI type define!');
% end
target_coord_sub = mni2subject_coords(cfgTarget.table.CoordMNI, m2mPath); % transform to subject space
%%
DT = mesh.DT;
c = incenter(DT);
target_node_idx = false(size(DT,1),cfgTarget.num);
for i = 1:cfgTarget.num
    target_node_idx(:,i) = vecnorm(c-target_coord_sub(i,:),2,2)<cfgTarget.table.Radius(i);
end
target_node_idx_all = any(target_node_idx,2);
%%
% elem_label = (1:size(DT))';
% % elem_idx = ismember(elem5,cfgTarget.matter);
% elem1 = DT.ConnectivityList(elem_idx,:);
% elem1_label = elem_label(elem_idx);
% %%
% DT1 = simpleTR(triangulation(elem1,DT.Points));
% ID1 = pointLocation(DT1,coord_sub);
% ID1 = ID1(~isnan(ID1));
% ID1_u = unique(ID1);
% ROI_idx = false(size(DT,1),1);
% ROI_idx(elem1_label(ID1_u)) = true;
end

