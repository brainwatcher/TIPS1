%% 参数设置
subnum = 1000;
session = 1;
freq1 = 2000;
freq2 = 2010;
amp1 = 1.6; 
amp2 = 0.4;
port1 = 3;%打开设备管理器看COM编号
port2 = 4;
stimtype = 233;% 233/666 两种模式
TI_time = 30; %单位：s

disp(['被试编号：' num2str(subnum)]);
disp(['刺激频率：' num2str(freq2-freq1)]);
disp(['刺激类型：' num2str(stimtype)]);
disp('请确认以上参数，确认无误后按空格键继续...');
pause
MEX_TI_Parameter(subnum,session,port1,port2,freq1,freq2);
disp('请检查信号源参数设置，确认无误后按空格键继续...');
pause
MEX_PerformTI(subnum,session,port1,port2,amp1,amp2,TI_time,stimtype);