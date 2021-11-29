dataRoot = 'C:\Users\psylab706\Documents\simnibs_examples';
subMark = 'ernie';
% datapath = 'E:\MyLabFiles\TI_Simulation\ernie'; %被试数据根目录
%% plot GM

[node,elem,simNIBS_face,conduct] = MeshfromSimnibs(dataRoot,subMark);
DT = simpleTR(triangulation(double(elem((elem(:,5)==2),1:4)),node));
figure;
plotmesh(DT.Points,DT.ConnectivityList,'y>0');
%%
mesh = mesh_load_gmsh4(fullfile(dataRoot,subMark,[subMark '.msh']));
gray_matter = mesh_extract_regions(mesh, 'region_idx', [1 2]);
[labels, snames] = subject_atlas(gray_matter,fullfile(dataRoot,subMark, ['m2m_' subMark]), 'DK40');%TODO
ROI.name = 'lh.insula';
ROI.multiple = 1;
path4saveLF = fullfile(datapath,'Result',ROI.name,['M' num2str(ROI.multiple)]);
LFfile = fullfile(path4saveLF,'LF.mat');
load(LFfile);
path4save = fullfile(path4saveLF,'R0_C0');
S = load(fullfile(path4save,'elec4.mat'),'U4m');
U = S.U4m;
[StimProtoco,gray_matter] = Elec_Parameter(U,LF);
showROI(gray_matter,path4save,1234,5678);