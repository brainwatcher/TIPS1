%% Path
dataRoot = cfg.dataRoot;
subMark = cfg.subMark;
simMark = cfg.simMark;
%% check headreco
SIMNIBS_headreco(dataRoot,subMark); % first time running for building mesh
%% simMark for this optimization
simDir = fullfile(dataRoot,subMark,'TI_sim_result',simMark);
%% log on
start = datestr(now);
diaryFile = name4diary(simDir); % file name depend on time
diary(diaryFile);
diary on
%% input for GPU
[Data,mesh] = prepare_LF(dataRoot,subMark,cfg);
%% 
WMntFile = fullfile(dataRoot,subMark,'orientation','nt_elem_WM.mat');
WM = load(WMntFile);
GMntFile = fullfile(dataRoot,subMark,'orientation','nt_elem_GM.mat');
GM = load(GMntFile);
nt = single([WM.nt_elem_WM;GM.nt_elem_GM]);
Epref = single(zeros(size(Data.E,1),size(Data.E,3)));
for i = 1:size(Data.E,3)
    Epref(:,i) = dot(Data.E(:,:,i),nt,2);
end
%%
disp('Define ROI region node index...');
ROI_idx = TargetRegionIdx(dataRoot,subMark,mesh,cfg.ROI,cfg.type);
E_ROI = Epref(ROI_idx,:);
area_ROI = Data.areas(ROI_idx);
if cfg.Penalty.num>0
    disp('Define Penalty region node index...');
    Penalty_idx = TargetRegionIdx(dataRoot,subMark,mesh,cfg.Penalty,cfg.type);
    Epref(Penalty_idx,:) = Epref(Penalty_idx,:) * cfg.Penalty.coef;
end
E_Other = Epref(~ROI_idx,:);
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
%%
clear Data;
%%
disp('Step 1. Calculate the Eam in ROI with prefered orientation for screen.');
gpuDevice(1);
tg1 = tic;
[A_ROI,C_ROI] = ROI_nt_Wrapper(Nr,E_ROI_p,cmb,cu,area_ROI_p,cfg.method_ROI);
disp(['GPU calculation takes time : ' num2str(toc(tg1)) ' s...']);
T1 = ROIScreen(A_ROI,C_ROI,cu,thres);
disp(['Survived combinations number is ' num2str(size(T1,1)) '...']);
%%
disp('Step 2. Calculate the Eam in Other brain area with screened parameters.');
gpuDevice(1);
tg2 = tic;
A_Other = Cortex_nt_Wrapper(No,E_Other_p,T1,area_Other_p,cfg.method_Other);
disp(['GPU calculation takes time : ' num2str(toc(tg2)) ' s...']);
T2 = CortexTable(T1,A_Other);
Tm = T2(1,:);
Um = T2U(Tm);
electrodes = Data.electrodes;
save(fullfile(workSpace,'elec4.mat'),'T2','Tm','Um','electrodes');
disp(Tm);
showU(Um);
%% log off
disp(['Start time : ' start])
disp(['End time : ' datestr(now)])
diary off
