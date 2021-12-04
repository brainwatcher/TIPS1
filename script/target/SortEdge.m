function es = SortEdge_new(e0)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
eRemain = e0;
es = cell(0,1);
i = 1;
while size(eRemain,1)>0
    [es{i},eRemain] = SortEdgeGiveEnd(eRemain,eRemain(1));
    i = i+1;
end
n = cellfun(@length,es,'un',1);
[~,k] = sort(n,'d');
es = es(k);
end

