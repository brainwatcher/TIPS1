function h = plotContour(h,EV,dof,varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
opt = varargin;
%% Contours C. make contour
figure(h);
hold on;
for i = 1:length(EV)
    x = EV{i}.Points(EV{i}.Edge(:,1),dof(1));
    y = EV{i}.Points(EV{i}.Edge(:,2),dof(2));
    plot(x,y,opt{:});
end
end

