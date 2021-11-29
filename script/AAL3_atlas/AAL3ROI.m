function ROI_coord_MNI = AAL3ROI(idx)
p = fileparts(mfilename('fullpath'));
aalDir = fullfile(p,'AAL3');
file = 'AAL3v1_1mm.nii';
v=spm_vol(fullfile(aalDir,file));
data=spm_read_vols(v);
%% ROI label
S = load(fullfile(aalDir,'ROI_MNI_V7_1mm_List.mat'));
ID = [S.ROI.ID]';
name = {S.ROI.Nom_L}';
i = find(ID==idx);
if isempty(i)
    error('No corresponding ROI label!');
else
    disp(['ROI name is ' name{i} '.']);
end
%%
data1 = false(size(data));
data1(data == idx) = true;
[vx,vy,vz] = ind2sub(size(data1),find(data1));
ROI_coord_MNI = vx2mm(v.mat,[vx,vy,vz]);
end

