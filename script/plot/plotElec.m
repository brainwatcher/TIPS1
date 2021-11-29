function plotElec(StimProtocol,elec,path4save)
% 绘制电极位置和电流强度
% 输入：StimProtocol 结构体，包含刺激的参数信息
%       path4save 数据存储路径

ele_r = 0.34;
h = maxfigwin();%绘图窗口最大化

%% The head
elec_circle([0 0],'',5,'k','none',2,'-',11);
elec_circle([0 0],'',4,'k','none',2,'-',11);
axis equal;
line([-5 5],[0 0],'Color','k','LineWidth',2);
line([0 0],[-5 5],'Color','k','LineWidth',2);
line([-0.5 0],[sqrt(25-0.5^2) 5.5],'Color','k','LineWidth',2);
line([0.5 0],[sqrt(25-0.5^2) 5.5],'Color','k','LineWidth',2);

%% Electrode postions
[Ele_array,Label] =  electrode_Pos();

Label_num = zeros(size(Label));
for ie = 1:size(Label,1)
    Label_num(ie,1) = find(strcmp(Label{ie,1},deblank(elec)));
end
Label_num = num2str(Label_num);

%% Electrodes to highlight
for i1 = 1:size(StimProtocol.ElecPair1,1)
    Idx_Elec1(i1,1) = find(strcmp(deblank(StimProtocol.ElecPair1{i1,1}),Label));
end
for i2 = 1:size(StimProtocol.ElecPair2,1)
    Idx_Elec2(i2,1) = find(strcmp(deblank(StimProtocol.ElecPair2{i2,1}),Label));
end


% load('Colormap.mat');
rang4cur = [-2:0.05:2];
Ncolor = size(rang4cur,2);
Idx_Cur1 = (StimProtocol.Current1 - (-2)*ones(size(StimProtocol.Current1)))/(4/Ncolor) + 1;
Idx_Cur2 = (StimProtocol.Current2 - (-2)*ones(size(StimProtocol.Current2)))/(4/Ncolor) + 1;

Colormap = cbrewer('div','Spectral', Ncolor); %设定colormap的颜色
Colormap(Colormap>1) = 1;
Colormap(Colormap<0) = 0;
Colormap = flipud(Colormap);

Ele4fre1 = Ele_array(Idx_Elec1,:);
Lab4fre1 = Label(Idx_Elec1,:);
Lab4fre1_num = Label_num(Idx_Elec1,:);
Col4fre1 = [255 127 0]./255;
col4fre1 = interp1(Colormap,Idx_Cur1,'linear');
col4fre1(col4fre1>1) = 1;
col4fre1(col4fre1<0) = 0;

Ele4fre2 = Ele_array(Idx_Elec2,:);
Lab4fre2 = Label(Idx_Elec2,:);
Lab4fre2_num = Label_num(Idx_Elec2,:);
Col4fre2 = [139 0 139]./255;
col4fre2 = interp1(Colormap,Idx_Cur2,'linear');
col4fre2(col4fre2>1) = 1;
col4fre2(col4fre2<0) = 0;

elec_circle(Ele4fre1,Lab4fre1,ele_r,'k',col4fre1,2,':',9);
elec_circle(Ele4fre2,Lab4fre2,ele_r,'k',col4fre2,2,'-.',9);

set(gca,'CLim',[-2 2],'Colormap',...
    Colormap,'DataAspectRatio',[1 1 1],'PlotBoxAspectRatio',[6.5 5 1]);
colorbar;

%% legend
elec_circle([-5 5],'',0.25,'k','w',2,':',9);
text(-4.3,5,'Fre1','FontSize',12,'HorizontalAlignment','center');
elec_circle([-5 4],'',0.25,'k','w',2,'-.',9);
text(-4.3,4,'Fre2','FontSize',12,'HorizontalAlignment','center');

%% Other electrodes
IdxElec = [Idx_Elec1;Idx_Elec2];
IdxElec = unique(IdxElec);
Ele_array(IdxElec,:) = [];
Label(IdxElec,:) = [];
Label_num(IdxElec,:) = [];
elec_circle(Ele_array,Label,ele_r,'k','w',1.5,'-',9);
axis off
%% save
saveas(gcf,fullfile(path4save,'elec.tif'));

%% Label the Elecs using the number
h = maxfigwin();%绘图窗口最大化

%% The head
elec_circle([0 0],'',5,'k','none',2,'-',11);
elec_circle([0 0],'',4,'k','none',2,'-',11);
axis equal;
line([-5 5],[0 0],'Color','k','LineWidth',2);
line([0 0],[-5 5],'Color','k','LineWidth',2);
line([-0.5 0],[sqrt(25-0.5^2) 5.5],'Color','k','LineWidth',2);
line([0.5 0],[sqrt(25-0.5^2) 5.5],'Color','k','LineWidth',2);

elec_circle(Ele4fre1,Lab4fre1_num,ele_r,'k',col4fre1,2,':',12);
elec_circle(Ele4fre2,Lab4fre2_num,ele_r,'k',col4fre2,2,'-.',12);

elec_circle([-5 5],'',0.25,'k','w',2,':',9);
text(-4.3,5,'Fre1','FontSize',12,'HorizontalAlignment','center');
elec_circle([-5 4],'',0.25,'k','w',2,'-.',9);
text(-4.3,4,'Fre2','FontSize',12,'HorizontalAlignment','center');

set(gca,'CLim',[-2 2],'Colormap',...
    Colormap,'DataAspectRatio',[1 1 1],'PlotBoxAspectRatio',[6.5 5 1]);
colorbar;

elec_circle(Ele_array,Label_num,ele_r,'k','w',1.5,'-',12);
axis off
saveas(gcf,fullfile(path4save,'elec_num.tif'));





