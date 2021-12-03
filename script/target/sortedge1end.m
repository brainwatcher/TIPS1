function [ e_sorted,v_tail,seq] = sortedge1end( e_pro,v_init )
%SORTEDGES
% [ e_sorted,v_end ] = sortedges( e_pro,v_init )
% e_pro the whole unsorted intersecting edges
% v_init the endpoint of one crossline
% e_sorted the fragment of sorted intersecting edges with
% endpoints(v_init,v_tail)
e_sorted=zeros(size(e_pro));
seq = zeros(size(e_pro,1),1);
[sub1,sub2]=ind2sub(size(e_pro),find(e_pro==v_init));
e_sorted(1,1)=e_pro(sub1,sub2);
e_sorted(1,2)=e_pro(sub1,mod(sub2,2)+1);
seq(1) = sub1;
sub0=sub1;
for i=2:size(e_pro,1)
    e_sorted(i,1)=e_sorted(i-1,2);
    [sub1,sub2]=ind2sub(size(e_pro),find(e_pro==e_sorted(i-1,2)));
    switch size(sub1,1)
        case 2
            if sub1(1)==sub0
                e_sorted(i,2)=e_pro(sub1(2),mod(sub2(2),2)+1);
                sub0=sub1(2);
                seq(i) = sub1(2);
            else
                e_sorted(i,2)=e_pro(sub1(1),mod(sub2(1),2)+1);
                sub0=sub1(1);
                seq(i) = sub1(1);
            end
        case 1
            break
        otherwise
            error('more than 2 endpoints for a crossline')
    end
end
e_sorted((e_sorted(:,2)==0),:)=[];
v_tail=e_sorted(end,2);
seq(seq==0)=[];
end

