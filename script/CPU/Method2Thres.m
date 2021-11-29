function [thres] = Method2Thres(method,thres0)
%METHOD2THRES Summary of this function goes here
%   Detailed explanation goes here
switch method
    case 0 % max
        thres = thres0;
    case 1 % mean
        thres = thres0;
    otherwise
        thres = thres0^method;
end
end

