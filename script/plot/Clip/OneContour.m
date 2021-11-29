function [edge,node] = OneContour(TR4,TR)
%ONECONTOUR Summary of this function goes here
%   Detailed explanation goes here
[~, intSurface] = SurfaceIntersection(TR4,TR);
node = intSurface.vertices;
edgeC = SortEdge(intSurface.edges);
if length(edgeC)>1
    [~,i] =  max(cellfun(@length,edgeC));
else
    i = 1;   
end
edge = edgeC{i};
end

