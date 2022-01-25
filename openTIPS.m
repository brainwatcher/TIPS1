function openTIPS(cfg)%% basic setting
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
%% ROI index

%% nt
if cfg.nt
    WMntFile = fullfile(dataRoot,subMark,'orientation','nt_elem_WM.mat');
    WM = load(WMntFile);
    GMntFile = fullfile(dataRoot,subMark,'orientation','nt_elem_GM.mat');
    GM = load(GMntFile);
    nt = single([WM.nt_elem_WM;GM.nt_elem_GM]);
    E_brain = single(zeros(size(Data.E,1),size(Data.E,3)));
    for i = 1:size(Data.E,3)
        E_brain(:,i) = dot(Data.E(:,:,i),nt,2);
    end
    % todo
else
    E = Data.E;
    clear Data;
end
area
%% target region index
disp('Define ROI region node index...');
ROI_idx = TargetRegionIdx(dataRoot,subMark,mesh,cfg.ROI,cfg.type);
E_ROI = Data.E(ROI_idx,:,:);
area_ROI = Data.areas(ROI_idx);
if cfg.Penalty.num>0
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
Tm = T2(1,:);
Um = T2U(Tm);
electrodes = Data.electrodes;
save(fullfile(simDir,'elec4.mat'),'T2','Tm','Um','electrodes');
disp(Tm);
showU(Um);
%% log off
disp(['Start time : ' start])
disp(['End time : ' datestr(now)])
diary off

%% plot electrode figure





