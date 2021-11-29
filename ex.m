%% 输入信息和参数
dataRoot = 'C:\Users\psylab706\Documents\simnibs_examples';%被试数据根目录
subMark = 'ernie';
simMark = 'test_tet_P_1_ACC';
resultPath = fullfile(dataRoot,subMark,'TI_sim_result',simMark);
%%
cfg = TIconfig(dataRoot,subMark,simMark);
%%
start = datestr(now);
diaryFile = name4diary(resultPath); % file name depend on time
diary(diaryFile);
diary on
%% input for GPU
inputFile = prepare_input(dataRoot,subMark,cfg);
load(inputFile);
switch cfg.type
    case 'tri'
        ROI_idx = ROISurf(dataRoot,subMark,gmS,cfg);
    case 'tet'
        ROI_idx = ROITet(dataRoot,subMark,DT,elem5,cfg);
end
if cfg.P == 0
    E_ROI = Data.E(ROI_idx,:,:);
    E_Other = Data.E(~ROI_idx,:,:);
    area_ROI = Data.areas(ROI_idx);
    area_Rest = Data.areas(~ROI_idx);
    %% padding
    [E_ROI_p,Nr] = zeroPadding(E_ROI,128);
    area_ROI_p = zeroPadding(area_ROI,128);
    [E_Other_p,No] = zeroPadding(E_Other,128);
    area_Other_p = zeroPadding(area_Rest,128);
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
    %% step 2, Rest sort
    disp('Step 2. Calculate the Eam in Other brain area with screened parameters.');
    gpuDevice(1);
    tg2 = tic;
    A_Rest = CortexWrapper(No,E_Other_p,T1,area_Other_p,cfg.method_Other);
    disp(['GPU calculation takes time : ' num2str(toc(tg2)) ' s...']);
    T2 = CortexTable(T1,A_Rest);
    T4m = T2(1,:);
    U4m = T2U(T4m);
    save(fullfile(resultPath,'elec4.mat'),'T2','T4m','U4m');
    %% step 3, multi-electrodes
end



%
% % ROI
% areaR = LF.NA_ROI;
%
% % Cortex
% areaC = LF.NA_Cortex;
% % zeropadding
%
% disp(['read data takes time : ' num2str(toc(t0)) ' s...']);
% %% ROI
%
% t1 = tic;
%
% T_Cortex = ROIScreen(A_ROI,C_ROI,cu1,thres);
% disp(['ROI phase takes time : ' num2str(toc(t1)) ' s...']);
% save(fullfile(path4save,'T_Cortex.mat'),'T_Cortex');
% %% Cortex
% t2 = tic;
% A_Cortex = CortexWrapper(Nc,EC0P,T_Cortex,areaCP,method_Cortex(j));
% T4 = CortexTable(T_Cortex,A_Cortex);
% disp(['CORTEX phase takes time : ' num2str(toc(t2)) ' s...']);
% T4m = T4(1,:);
% U4m = T2U(T4m);
% save(fullfile(path4save,'elec4.mat'),'T4','T4m','U4m');
% %% Elec6
% k6_in = 100;
% k6_out = 100;
% if(k6_in>size(T4,1))
%     error('Not enough candidate number in elec6!');
% end
% disp(['There are ' num2str(k6_in) ' candidate montage to be modified in elec6.']);
% T6a = cell(k6_in,1);
% U6a = cell(k6_in,1);
% t = tic;
% for i = 1:k6_in
%     T4i = T4(i,:);
%     U4i = T2U(T4i);
%     C0 = FreeC0([U4i.a.elec,U4i.b.elec],2);
%     Ci = [C0;C0(:,[2,1])];
%     cu6 = makeCu6(0.7,U4i);
%     [T6a{i},U6a{i}] = Elec6Shell(Nr,ER0P,areaRP,Nc,EC0P,areaCP,method_ROI(j),method_Cortex(j),cu6,Ci,U4i,thres,T4.R(1),k6_out);
% end
% [T6,U6] = Bigk(T6a,U6a,k6_out);
% if(~isempty(T6))
%     U6m = U6{1};
%     T6m = T6(1,:);
%     showU(U6m);
%     disp(T6m);
%     T6mcpu = tryOnetime(U6m,LF.E_ROI,LF.E_Cortex,areaR,areaC,method_ROI(j),method_Cortex(j));
%     disp('cpu check...');
%     disp(T6mcpu);
%     disp(['Elec6 : ' num2str(toc(t)) ' s...']);
%     save(fullfile(path4save,'elec6.mat'),'T6','U6','T6m','U6m');
%     disp(['6 elec improves ' num2str((T6m.R-T4.R(1))/T4.R(1)*100) '% than 4 elec montage.']);
%     Ufinal = U6m;
% else
%     disp('Elec4 to 6 has no improvement');
%     Ufinal = U4m;
% end
% %% Elec8
% t = tic;
% k8_in = 20;% User Define
% k8_out = 100;
% if(k8_in > k6_out)
%     error('Not enough candidate number in elec8!');
% end
% disp(['There are ' num2str(k8_in) ' candidate montage to be modified in elec8.']);
% T8a = cell(k8_in,1);
% U8a = cell(k8_in,1);
% for i = 1:k8_in
%     cu8 = makeCuBeta8(0.7,U6{i});
%     C0 = FreeC0([U6{i}.a.elec,U6{i}.b.elec],2);
%     Ci = [C0;C0(:,[2,1])];
%     [T8a{i},U8a{i}] = Elec8Shell(Nr,ER0P,areaRP,Nc,EC0P,areaCP,method_ROI(j),method_Cortex(j),cu8,Ci,U6{i},thres,T6m.R,k8_out);
% end
% [T8,U8] = Bigk(T8a,U8a,k8_out);
% if(~isempty(T8))
%     U8m = U8{1};
%     T8m = T8(1,:);
%     showU(U8m);
%     disp(T8m);
%     T8mcpu = tryOnetime(U8m,LF.E_ROI,LF.E_Cortex,areaR,areaC,method_ROI(j),method_Cortex(j));
%     disp('cpu check...');
%     disp(T8mcpu);
%     disp(['Elec8 : ' num2str(toc(t)) ' s...']);
%     save(fullfile(path4save,'elec8.mat'),'T8','U8','T8m','U8m');
%     disp(['8 elec improves ' num2str((T8m.R-T6m.R)/T6m.R*100) '% than 6 elec montage.']);
%     disp(['8 elec improves ' num2str((T8m.R-T4.R(1))/T4.R(1)*100) '% than 4 elec montage.']);
%     Ufinal = U8m;
% else
%     disp('Elec 6 to 8 has no improvements');
% end
% %% 绘图
% %电极位置和电流分配数据提取
% %每种方法组合的刺激方案和TI_ROI,TI_Cortex场强值都存在这个大cell里
% [StimProtocol{j},gray_matter] = Elec_Parameter(Ufinal,LF);
% StimProtocol{j}.method_ROI = method_ROI(j);
% StimProtocol{j}.method_Cortex = method_Cortex(j);
% %绘制电极位置和电流分配图
% plotElec(StimProtocol{j},LF.electrodes,path4save);
% %ROI结构图示
% showROI(gray_matter,path4save,1234,5678);
% %全脑场强分布图
% plotCortex(gray_matter,path4save,[]);
% %突出ROI的全脑场强分布
% plotROI(gray_matter,path4save,[]);
% close all % 关闭图片，节省内存
% %% 关闭日志文件
% disp(['Start time : ' start])
% disp(['End time : ' datestr(now)])
% diary off
% end
% end



