function h = plotContour(h,EV,dof,varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
opt = varargin;
%% Contours C. make contour
figure(h);
hold on;
n = size(EV.Edge,1);
x = zeros(n+1,1);
y = zeros(n+1,1);
x(1:n) = EV.Points(EV.Edge(:,1),dof(1));
y(1:n) = EV.Points(EV.Edge(:,2),dof(2));
x(end) = x(1);
y(end) = y(1);
plot(x,y,opt{:});
end

