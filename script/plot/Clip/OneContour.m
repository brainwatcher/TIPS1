function [edgeC,node] = OneContour(TR4,TR)
%ONECONTOUR Summary of this function goes here
%   Detailed explanation goes here
[~, intSurface] = SurfaceIntersection(TR4,TR);
node = intSurface.vertices;
try
    edgeC = SortEdge(intSurface.edges);
catch
    edgeC = SortEdgeNoEnd(intSurface.edges);
end
% if length(edgeC)>1
%     [~,i] =  max(cellfun(@length,edgeC));
% else
%     i = 1;
% end
% if ~isempty(edgeC)
%     edge = edgeC{i};
% else
%     edge = [];
% end
end

