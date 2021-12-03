function [edge_sorted,index_end,seq] = SortEdge(edge,varargin)
%SORTEDGE [edge_sorted,index_end,seq] = sortedge(edge,varargin)
% edge: input edge sequence, n*2 
% varargin : input one end of edge has two ends , 1*1
% edge_sorted : as name , n*2
% index_end : 1*2 end of edge, if it has
% seq : the index of origin edge in edge_sorted
[gc,gr] = groupcounts(edge(:));
if any(gc>2)
    error('some points appears 3 more times...');
end
if mod(sum(gc==1),2) ==1
    error('the num of 1 appearance point is not corrected...');
end
switch sum(gc==1)
    case 2
        if nargin>1
            end_1 = varargin{1};
        else
            end_pool = gr(gc==1);
            end_1 = end_pool(1);
        end
            [edge_sorted,end_2] = sortedge1end(edge,end_1);     
            index_end = [end_1,end_2];
            seq = [];
    case 0
        [edge_sorted,seq] = SortEdgeNoEnd(edge); 
        index_end = [];
end
if sum(gc==1)>2
    end_pool = gr(gc==1);
    edge_tmp = edge;
    edge_sorted = [];
    index_end=[];
    seq = [];
    while ~isempty(end_pool)
        end_1 = end_pool(1);
        [edge_sorted_tmp,end_2,seq0] = sortedge1end(edge_tmp,end_1);
        end_pool = setdiff(end_pool,[end_1,end_2]);
        edge_sorted = [edge_sorted;edge_sorted_tmp];
        edge_tmp = edge_tmp(setdiff(1:size( edge_tmp,1),seq0),:);
        index_end=[index_end;[end_1,end_2]];
    end
    
end
end

