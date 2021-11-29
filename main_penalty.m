%% 输入信息和参数
datapath = 'C:\Users\psylab706\Documents\simnibs_examples\ernie'; %被试数据根目录

% datapath = 'E:\MyLabFiles\TI_Simulation\ernie'; %被试数据根目录
ROI.name = 'lh.caudalanteriorcingulate';
ROI.multiple = 1;% 将ROI区域向外扩展的倍数，超出ROI的区域在计算过程中被“抠除”;若不需要扩展，设置为<=1的数即可
Penalty_coef = [2.8 2.1]; %惩罚区域电场乘以的倍数
[~,subname] = fileparts(datapath);

for i_p = 1:length(Penalty_coef)
    %% 依据ROI和Cortex进行leadfield 的后处理（依赖simnibs的函数）
    ROI.method = 'DK40';%后续继续添加更多的方法，包括根据MNI坐标画球，ROI周围扣去一圈等等等等
    
    %仅以ROI（拓展）区域以外的位置作为Cortex
    % Cortex.method = 'OutROI';
    
    %在以ROI（拓展）区域以外的位置作为Cortex的基础上，以‘DK40’地图集找特定Cortex区域进行更多的惩罚
    Cortex.method = 'DK40';
    % Cortex.penalty_areas = {'lh.caudalmiddlefrontal';'lh.lateralorbitofrontal';'lh.medialorbitofrontal';...
    % 'lh.paracentral'; 'lh.postcentral';'lh.posteriorcingulate'; 'lh.precentral'; 'lh.rostralanteriorcingulate';...
    % 'lh.rostralmiddlefrontal';'lh.superiorfrontal'; 'lh.frontalpole'; 'lh.parstriangularis';'lh.parsopercularis';...
    % 'lh.parsorbitalis';'rh.caudalmiddlefrontal';'rh.lateralorbitofrontal';'rh.medialorbitofrontal';...
    % 'rh.paracentral'; 'rh.postcentral';'rh.posteriorcingulate'; 'rh.precentral'; 'rh.rostralanteriorcingulate';...
    % 'rh.rostralmiddlefrontal';'rh.superiorfrontal'; 'rh.frontalpole'; 'rh.parstriangularis';'rh.parsopercularis';...
    % 'rh.parsorbitalis';};
    Cortex.penalty_areas = {'lh.rostralmiddlefrontal';'rh.rostralmiddlefrontal'};
    Cortex.penalty_coef = Penalty_coef(1,i_p);
    
    path4saveLF = fullfile(datapath,'Result',ROI.name,['P_' num2str(Penalty_coef(1,i_p))]);
    if ~exist(path4saveLF,'dir')
        mkdir(path4saveLF);
    end
    LFfile = fullfile(path4saveLF,'LF.mat');
    if ~exist(LFfile,'file')
        disp('Get ROI data from pre calculated leadfield...');
        LF = postprocess_leadfield(subname,datapath,...
            ROI,Cortex);
        saveas(gcf,fullfile(path4saveLF,'Expansion of ROI.fig'));
        close all
        save(LFfile,'LF');
    else
        load(LFfile);
        disp('ROI data existed...');
    end
    
    if sum(LF.ROI_idx,1) + sum(LF.OutROI_idx,1) ~= length(LF.ROI_idx)
        disp('N_ROI + N_Cortex ~= N_gray_matter, please check ...')
        break;
    end
    %ROI结构图示
    showROI(LF.gray_matter,path4saveLF,1234,[5678 666]);% showROI(gray_matter,savepath,ROI_label,TakeOut_label) 如果不想看惩罚区域，可以把惩罚区域置[]
    % TakeOut_label:5678--由ROI拓展而来；666--根据DK40的脑区标签选取而来
    close all
    %%
    % method : 0 max ; 1 mean ; 2 square ,etc
    method_ROI = [0,0,0,0,2,2];
    method_Cortex = [0,2,4,6,2,4];
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
        Name4diary = name4diary(path4save,subname,ROI.name); % 按照当前时刻为 diary文件生成名字，避免后来的文件把之前的覆盖
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
        Ufinal = U4m;
        %% 绘图
        path4save_4m = fullfile(path4save,'Fig_4m');
        if ~exist(path4save_4m,'dir')
            mkdir(path4save_4m);
        end
        %电极位置和电流分配数据提取
        %每种方法组合的刺激方案和TI_ROI,TI_Cortex场强值都存在这个大cell里
        [StimProtocol{j},gray_matter] = Elec_Parameter(Ufinal,LF);
        StimProtocol{j}.method_ROI = method_ROI(j);
        StimProtocol{j}.method_Cortex = method_Cortex(j);
        %绘制电极位置和电流分配图
        plotElec(StimProtocol{j},LF.electrodes,path4save_4m);
        %全脑场强分布图
        plotCortex(gray_matter,path4save_4m,[]);
        %突出ROI的全脑场强分布
        plotROI(gray_matter,path4save_4m,[]);
        close all % 关闭图片，节省内存
        
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
        %% 绘图
        path4save_6m = fullfile(path4save,'Fig_6m');
        if ~exist(path4save_6m,'dir')
            mkdir(path4save_6m);
        end
        %电极位置和电流分配数据提取
        %每种方法组合的刺激方案和TI_ROI,TI_Cortex场强值都存在这个大cell里
        [StimProtocol{j},gray_matter] = Elec_Parameter(Ufinal,LF);
        StimProtocol{j}.method_ROI = method_ROI(j);
        StimProtocol{j}.method_Cortex = method_Cortex(j);
        %绘制电极位置和电流分配图
        plotElec(StimProtocol{j},LF.electrodes,path4save_6m);
        %全脑场强分布图
        plotCortex(gray_matter,path4save_6m,[]);
        %突出ROI的全脑场强分布
        plotROI(gray_matter,path4save_6m,[]);
        close all % 关闭图片，节省内存
%         %% Elec8
%         t = tic;
%         k8_in = 20;% User Define
%         k8_out = 100;
%         if(k8_in > k6_out)
%             error('Not enough candidate number in elec8!');
%         end
%         disp(['There are ' num2str(k8_in) ' candidate montage to be modified in elec8.']);
%         T8a = cell(k8_in,1);
%         U8a = cell(k8_in,1);
%         for i = 1:k8_in
%             cu8 = makeCuBeta8(0.7,U6{i});
%             C0 = FreeC0([U6{i}.a.elec,U6{i}.b.elec],2);
%             Ci = [C0;C0(:,[2,1])];
%             [T8a{i},U8a{i}] = Elec8Shell(Nr,ER0P,areaRP,Nc,EC0P,areaCP,method_ROI(j),method_Cortex(j),cu8,Ci,U6{i},thres,T6m.R,k8_out);
%         end
%         [T8,U8] = Bigk(T8a,U8a,k8_out);
%         if(~isempty(T8))
%             U8m = U8{1};
%             T8m = T8(1,:);
%             showU(U8m);
%             disp(T8m);
%             T8mcpu = tryOnetime(U8m,LF.E_ROI,LF.E_Cortex,areaR,areaC,method_ROI(j),method_Cortex(j));
%             disp('cpu check...');
%             disp(T8mcpu);
%             disp(['Elec8 : ' num2str(toc(t)) ' s...']);
%             save(fullfile(path4save,'elec8.mat'),'T8','U8','T8m','U8m');
%             disp(['8 elec improves ' num2str((T8m.R-T6m.R)/T6m.R*100) '% than 6 elec montage.']);
%             disp(['8 elec improves ' num2str((T8m.R-T4.R(1))/T4.R(1)*100) '% than 4 elec montage.']);
%             Ufinal = U8m;
%         else
%             disp('Elec 6 to 8 has no improvements');
%         end
%         %% 绘图
%         path4save_8m = fullfile(path4save,'Fig_8m');
%         if ~exist(path4save_8m,'dir')
%             mkdir(path4save_8m);
%         end
%         %电极位置和电流分配数据提取
%         %每种方法组合的刺激方案和TI_ROI,TI_Cortex场强值都存在这个大cell里
%         [StimProtocol{j},gray_matter] = Elec_Parameter(Ufinal,LF);
%         StimProtocol{j}.method_ROI = method_ROI(j);
%         StimProtocol{j}.method_Cortex = method_Cortex(j);
%         %绘制电极位置和电流分配图
%         plotElec(StimProtocol{j},LF.electrodes,path4save_8m);
%         %全脑场强分布图
%         plotCortex(gray_matter,path4save_8m,[]);
%         %突出ROI的全脑场强分布
%         plotROI(gray_matter,path4save_8m,[]);
%         close all % 关闭图片，节省内存
        %% 关闭日志文件
        disp(['Start time : ' start])
        disp(['End time : ' datestr(now)])
        diary off
    end
end
