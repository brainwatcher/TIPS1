%% 说明
% 数据文件组织形式：被试的T1和T2结构像数据存储在以受试者编号等标识[subname]命名的文件夹中，该文件夹为总的数据根目录 ‘datapath’
% 该根目录下应包含受试者的T1和T2像的 .nii 数据
% 并分别以‘[subname]_TI.nii’'[subname]_T2.nii'的形式命名
% 注意！！！ 'datapath'路径中不能含有空格，否则头模型建立会出错！！！

% 如果没有进行头模型建立的话先运行 headreco 进行头模型的创建，‘subname’代表受试者的编号等标识，得到的头模型数据
% 'm2m_[subname]'文件夹、 '[subname].msh'文件、
% '[subname]_T1ls_conform.nii.gz'压缩文件在‘datapath’根目录下

% 如果没有进行过leadfield计算的话就先进行leadfield的计算，算得的 ‘leadfield’ 文件夹为 ‘datapath’根目录的第一级子文件夹

% 计算结果保存在 ‘datapath’ 根目录下，第一级子文件夹为 ROI
% 的名称和划分ROI的方法，例如‘DK40_insula’表示ROI脑区为使用DK40地图集标记的左侧脑岛；目前主要基于DK40，后续会添加其他方法

%% 头模型建立 headreco 从属于simnibs
% cd(datapath);
% T1 = dir('*_T1.nii');
% T2 = dir('*_T2.nii');
% if size(T1,1) ~= 1 || size(T1,1) ~= 1
%     disp('Wrong T1 or T2 data, please check!');
% end
% [status,results] = system(['headreco all ernie ' T1.name ' ' T2.name]);

%% leadfield 计算 simnibs
% tdcs_lf = sim_struct('TDCSLEADFIELD');
% % Head mesh
% tdcs_lf.fnamehead = fullfile(datapath,[subname '.msh']);
% % Output directory
% tdcs_lf.pathfem = fullfile(datapath,'leadfield');
% run_simnibs(tdcs_lf)
%% 计算灰质和白质的方向
