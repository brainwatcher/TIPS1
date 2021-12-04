%% 输入信息和参数
dataRoot = 'C:\Users\psylab706\Documents\simnibs_examples';%被试数据根目录
subMark = 'ernie';
simMark = 'test_tet_ACC_noPenalty_r5_mO2';
workSpace = fullfile(dataRoot,subMark,'TI_sim_result',simMark);
%%
cfg = TIconfig(dataRoot,subMark,simMark);
%%
start = datestr(now);
diaryFile = name4diary(workSpace); % file name depend on time
diary(diaryFile);
diary on
%% input for GPU
[Data,mesh] = prepare_LF(dataRoot,subMark,cfg);
%% target region index
disp('Define ROI region node index...');
ROI_idx = TargetRegionIdx(dataRoot,subMark,mesh,cfg.ROI,cfg.type);
E_ROI = Data.E(ROI_idx,:,:);
area_ROI = Data.areas(ROI_idx);
if isfield(cfg,'Penalty')
    disp('Define Penalty region node index...');
    Penalty_idx = TargetRegionIdx(dataRoot,subMark,mesh,cfg.Penalty,cfg.type);
    Data.E(Penalty_idx,:,:) = Data.E(Penalty_idx,:,:) * cfg.Penalty.coef;
end
E_Other = Data.E(~ROI_idx,:,:);
area_Other = Data.areas(~ROI_idx);
%% padding
[E_ROI_p,Nr] = zeroPadding(E_ROI,128);
area_ROI_p = zeroPadding(area_ROI,128);
[E_Other_p,No] = zeroPadding(E_Other,128);
area_Other_p = zeroPadding(area_Other,128);
%% combination
cmb = int32(nchoosek(1:size(Data.electrodes,1),4));
%%
thres = Method2Thres(cfg.method_ROI,cfg.thres);
cu = (0.5+(0:20)*0.05)';
%% step 1, ROI screen
disp('Step 1. Calculate the Eam in ROI for screen.');
gpuDevice(1);
tg1 = tic;
[A_ROI,C_ROI] = ROIWrapper(Nr,E_ROI_p,cmb,cu,area_ROI_p,cfg.method_ROI);
disp(['GPU calculation takes time : ' num2str(toc(tg1)) ' s...']);
T1 = ROIScreen(A_ROI,C_ROI,cu,thres);
disp(['Survived combinations number is ' num2str(size(T1,1)) '...']);
%% step 2, Other sort
disp('Step 2. Calculate the Eam in Other brain area with screened parameters.');
gpuDevice(1);
tg2 = tic;
A_Other = CortexWrapper(No,E_Other_p,T1,area_Other_p,cfg.method_Other);
disp(['GPU calculation takes time : ' num2str(toc(tg2)) ' s...']);
T2 = CortexTable(T1,A_Other);
T4m = T2(1,:);
U4m = T2U(T4m);
electrodes = Data.electrodes;
save(fullfile(workSpace,'elec4.mat'),'T2','T4m','U4m','electrodes');
disp(T4m);
showU(U4m);
%% 关闭日志文件
disp(['Start time : ' start])
disp(['End time : ' datestr(now)])
diary off
%% 




