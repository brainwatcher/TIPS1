function [Data,DT,elem5] = LFTet(dataRoot,subMark)
%LFTET Summary of this function goes here
%   Detailed explanation goes here
LFPath = fullfile(dataRoot,subMark,'leadfieldAll');
LFFile = fullfile(LFPath,[subMark '_leadfield_EEG10-10_UI_Jurak_2007.hdf5']);
if exist(LFFile,'file')~=2
    error('Leadfield file for whole brain not existed! Please run prepare script.');
end
%%
disp('Loading whole brain tetrahedral hdf5 file...');
tic;
m0 = mesh_load_hdf5(LFFile);
toc;
%%
elem_idx = ismember(m0(2).mesh.tetrahedron_regions,[1,2]);
elem = m0(2).mesh.tetrahedra(elem_idx,:);
DT = simpleTR(triangulation(double(elem),m0(2).mesh.nodes));
elem5 = m0(2).mesh.tetrahedron_regions(elem_idx);
%%
area0 = mesh_get_tetrahedron_sizes(m0(2).mesh);
Data.areas = single(area0(elem_idx));
Data.electrodes = m0(2).lf.properties.electrode_names; 
n = size(DT.ConnectivityList,1);
Data.E = single(zeros(n,3,76));
Data.E(:,:,2:end)= single(permute(m0(2).lf.data(:,elem_idx,:),[2,1,3])/1000);
end

