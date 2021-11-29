%% 输入信息和参数
dataRoot = 'C:\Users\psylab706\Documents\simnibs_examples';%被试数据根目录
subMark = 'ernie'; 
%%
ROIinfo.type = 'atlas';% atlas, coord
ROIinfo.atlas = 'DK40';
ROIinfo.name = 'lh.caudalanteriorcingulate';
ROIinfo.coord_MNI = [0,0,0];
%%
typeBool = 0; % 0, surf; 1, tetrahedron
orientationBool = 0;
penaltyBool = 0;
%%
switch typeBool 
    case 0
    [Data,gmS] = LFSurf(dataRoot,subMark);
    [ROI_E_idx] = ROISurf(dataRoot,subMark,gmS,ROIinfo);
    if penaltyBool
        penalty_E_idx = ROISurf(dataRoot,subMark,gmS,penaltyinfo);
    end
end

ROI.multiple = 1;% 将ROI区域向外扩展的倍数，超出ROI的区域在计算过程中被“抠除”
%% build ROI

%%
for i_m = 1:length(ROI.multiple)
    %% 依据ROI进行leadfield 的后处理（依赖simnibs的函数）
    ROI.method = 'DK40';%后续继续添加更多的方法，包括根据MNI坐标画球，ROI周围扣去一圈等等等等
    %仅以ROI（拓展）区域以外的位置作为Cortex
    Cortex.method = 'OutROI';
    Cortex.penalty_coef = 1;% Cortex的惩罚倍数，即 PR = A_ROI/(Cortex.penalty_coef.*A_Cortex)
    path4saveLF = fullfile(datapath,'Result',ROI.name,['M' num2str(ROI.multiple(1,i_m))]);
    if ~exist(path4saveLF,'dir')
        mkdir(path4saveLF);
    end
    LFfile = fullfile(path4saveLF,'LF.mat');
    if ~exist(LFfile,'file')
        disp('Get ROI data from pre calculated leadfield...');
        LF = postprocess_leadfield(subMark,dataRoot,ROI,Cortex);
        save(LFfile,'LF');
    else
        S = load(LFfile);
        LF = S.LF;
        clear S;
        disp('ROI data existed...');
    end
    %%
    %     method_ROI = 0;
    %     method_Cortex = 0 ;
    method_ROI = [0,0,1,0,0];
    method_Cortex = [0,1,1,2,4];
    if length(method_ROI) ~= length(method_Cortex)
        error('wrong method input format...');
    end
    thres0 = 0.2;
    StimProtocol = cell(length(method_ROI),1);
    for j = 1:length(method_ROI)
        % 依据计算的method进行结果文件夹的命名，避免文件覆盖
        path4save = fullfile(path4saveLF,['R' num2str(method_ROI(j)) '_C' num2str(method_Cortex(j))]);
        if ~exist(path4save,'dir')
            mkdir(path4save);
        end
        %% 优化计算 只对输入数据进行了修改
        start = datestr(now);
        Name4diary = name4diary(path4save,subMark,ROI.name); % 按照当前时刻为 diary文件生成名字，避免后来的文件把之前的覆盖
        diary(Name4diary);
        diary on
        gpuDevice(1);
        %% read leadfield and area data
        t0 = tic;
        % ROI
        areaR = LF.NA_ROI;
        c0 = LF.c0;
        % Cortex
        areaC = LF.NA_Cortex;
        % zeropadding
        [ER0P,Nr] = zeroPadding(LF.E_ROI,128);
        areaRP = zeroPadding(areaR,128);
        [EC0P,Nc] = zeroPadding(LF.E_Cortex,128);
        areaCP = zeroPadding(areaC,128);
        disp(['read data takes time : ' num2str(toc(t0)) ' s...']);
        %% ROI
        thres = Method2Thres(method_ROI(j),thres0);
        cu1 = (0.5+(0:20)*0.05)';
        t1 = tic;
        [A_ROI,C_ROI] = ROIWrapper(Nr,ER0P,c0,cu1,areaRP,method_ROI(j));
        T_Cortex = ROIScreen(A_ROI,C_ROI,cu1,thres);
        disp(['ROI phase takes time : ' num2str(toc(t1)) ' s...']);
        save(fullfile(path4save,'T_Cortex.mat'),'T_Cortex');
        %% Cortex
        t2 = tic;
        A_Cortex = CortexWrapper(Nc,EC0P,T_Cortex,areaCP,method_Cortex(j));
        T4 = CortexTable(T_Cortex,A_Cortex);
        disp(['CORTEX phase takes time : ' num2str(toc(t2)) ' s...']);
        T4m = T4(1,:);
        U4m = T2U(T4m);
        save(fullfile(path4save,'elec4.mat'),'T4','T4m','U4m');
        %% Elec6
        k6_in = 100;
        k6_out = 100;
        if(k6_in>size(T4,1))
            error('Not enough candidate number in elec6!');
        end
        disp(['There are ' num2str(k6_in) ' candidate montage to be modified in elec6.']);
        T6a = cell(k6_in,1);
        U6a = cell(k6_in,1);
        t = tic;
        for i = 1:k6_in
            T4i = T4(i,:);
            U4i = T2U(T4i);
            C0 = FreeC0([U4i.a.elec,U4i.b.elec],2);
            Ci = [C0;C0(:,[2,1])];
            cu6 = makeCu6(0.7,U4i);
            [T6a{i},U6a{i}] = Elec6Shell(Nr,ER0P,areaRP,Nc,EC0P,areaCP,method_ROI(j),method_Cortex(j),cu6,Ci,U4i,thres,T4.R(1),k6_out);
        end
        [T6,U6] = Bigk(T6a,U6a,k6_out);
        if(~isempty(T6))
            U6m = U6{1};
            T6m = T6(1,:);
            showU(U6m);
            disp(T6m);
            T6mcpu = tryOnetime(U6m,LF.E_ROI,LF.E_Cortex,areaR,areaC,method_ROI(j),method_Cortex(j));
            disp('cpu check...');
            disp(T6mcpu);
            disp(['Elec6 : ' num2str(toc(t)) ' s...']);
            save(fullfile(path4save,'elec6.mat'),'T6','U6','T6m','U6m');
            disp(['6 elec improves ' num2str((T6m.R-T4.R(1))/T4.R(1)*100) '% than 4 elec montage.']);
            Ufinal = U6m;
        else
            disp('Elec4 to 6 has no improvement');
            Ufinal = U4m;
        end
        %% Elec8
        t = tic;
        k8_in = 20;% User Define
        k8_out = 100;
        if(k8_in > k6_out)
            error('Not enough candidate number in elec8!');
        end
        disp(['There are ' num2str(k8_in) ' candidate montage to be modified in elec8.']);
        T8a = cell(k8_in,1);
        U8a = cell(k8_in,1);
        for i = 1:k8_in
            cu8 = makeCuBeta8(0.7,U6{i});
            C0 = FreeC0([U6{i}.a.elec,U6{i}.b.elec],2);
            Ci = [C0;C0(:,[2,1])];
            [T8a{i},U8a{i}] = Elec8Shell(Nr,ER0P,areaRP,Nc,EC0P,areaCP,method_ROI(j),method_Cortex(j),cu8,Ci,U6{i},thres,T6m.R,k8_out);
        end
        [T8,U8] = Bigk(T8a,U8a,k8_out);
        if(~isempty(T8))
            U8m = U8{1};
            T8m = T8(1,:);
            showU(U8m);
            disp(T8m);
            T8mcpu = tryOnetime(U8m,LF.E_ROI,LF.E_Cortex,areaR,areaC,method_ROI(j),method_Cortex(j));
            disp('cpu check...');
            disp(T8mcpu);
            disp(['Elec8 : ' num2str(toc(t)) ' s...']);
            save(fullfile(path4save,'elec8.mat'),'T8','U8','T8m','U8m');
            disp(['8 elec improves ' num2str((T8m.R-T6m.R)/T6m.R*100) '% than 6 elec montage.']);
            disp(['8 elec improves ' num2str((T8m.R-T4.R(1))/T4.R(1)*100) '% than 4 elec montage.']);
            Ufinal = U8m;
        else
            disp('Elec 6 to 8 has no improvements');
        end
        %% 绘图
        %电极位置和电流分配数据提取
        %每种方法组合的刺激方案和TI_ROI,TI_Cortex场强值都存在这个大cell里
        [StimProtocol{j},gray_matter] = Elec_Parameter(Ufinal,LF);
        StimProtocol{j}.method_ROI = method_ROI(j);
        StimProtocol{j}.method_Cortex = method_Cortex(j);
        %绘制电极位置和电流分配图
        plotElec(StimProtocol{j},LF.electrodes,path4save);
        %ROI结构图示
        showROI(gray_matter,path4save,1234,5678);
        %全脑场强分布图
        plotCortex(gray_matter,path4save,[]);
        %突出ROI的全脑场强分布
        plotROI(gray_matter,path4save,[]);
        close all % 关闭图片，节省内存
        %% 关闭日志文件
        disp(['Start time : ' start])
        disp(['End time : ' datestr(now)])
        diary off
    end
end



