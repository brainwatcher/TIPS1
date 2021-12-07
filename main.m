% 输入信息和参数
dataRoot = 'E:\Ginger\simnibs_examples';%被试数据根目录
subMark = 'ernie';
simMark = 'ACC_r5_mO2_mR0_P2_r30';
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
% %% step3. Elec6
% k6_in = 100;
% k6_out = 100;
% if(k6_in>size(T2,1))
%     error('Not enough candidate number in elec6!');
% end
% disp(['There are ' num2str(k6_in) ' candidate montage to be modified in elec6.']);
% T6a = cell(k6_in,1);
% U6a = cell(k6_in,1);
% t = tic;
% for i = 1:k6_in
%     T2i = T2(i,:);
%     U4i = T2U(T2i);
%     C0 = FreeC0([U4i.a.elec,U4i.b.elec],2);
%     Ci = [C0;C0(:,[2,1])];
%     cu6 = makeCu6(0.7,U4i);
%     [T6a{i},U6a{i}] = Elec6Shell(Nr,E_ROI_p,area_ROI_p,No,E_Other_p,area_Other_p,cfg.method_ROI,cfg.method_Other,cu6,Ci,U4i,thres,T2.Ratio(1),k6_out);
% end
% [T6,U6] = Bigk(T6a,U6a,k6_out);
% if(~isempty(T6))
%     U6m = U6{1};
%     T6m = T6(1,:);
%     showU(U6m);
%     disp(T6m);
%     T6mcpu = tryOnetime(U6m,E_ROI,E_Other,area_ROI,area_Other,cfg.method_ROI,cfg.method_Other);
%     disp('cpu check...');
%     disp(T6mcpu);
%     disp(['Elec6 : ' num2str(toc(t)) ' s...']);
%     save(fullfile(workSpace,'elec6.mat'),'T6','U6','T6m','U6m','electrodes');
%     disp(['6 elec improves ' num2str((T6m.R-T2.Ratio(1))/T2.Ratio(1)*100) '% than 4 elec montage.']);
%     Ufinal = U6m;
% else
%     disp('Elec4 to 6 has no improvement');
%     Ufinal = U4m;
% end
% 关闭日志文件
disp(['Start time : ' start])
disp(['End time : ' datestr(now)])
diary off
%




