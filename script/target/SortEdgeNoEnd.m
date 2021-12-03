function [eOut,seqOut] = SortEdgeNoEnd(e)
% sorted a closed intersecting curve,no ends
N = size(e,1);
eRemain = true(N,1);
k = 0;
seq = (1:N)';
eOut = cell(0,1);
seqOut = cell(0,1);
%%
while any(eRemain)
    k = k+1;
    Nk = sum(eRemain);
    ek = e(eRemain,:);
    seqk = seq(eRemain);
    e0 = zeros(Nk,2);
    seq0 = zeros(Nk,1);
    %% intial
    e0(1,:)=ek(1,:);
    seq0(1)=seqk(1);
    sub0 = 1;
    for i=2:Nk
        if e0(i-1,2)~=e0(1,1)
            e0(i,1)=e0(i-1,2);
            [sub1,sub2]=ind2sub(size(ek),find(ek==e0(i-1,2)));
            if sub1(1)==sub0
                e0(i,2)=ek(sub1(2),mod(sub2(2),2)+1);
                sub0=sub1(2);
            else
                e0(i,2)=ek(sub1(1),mod(sub2(1),2)+1);
                sub0=sub1(1);
            end
            seq0(i)=seqk(sub0);
        else
            e0(i:end,:)=[];
            seq0(i:end)=[];
            eRemain(seq0)=false;
            eOut{k} = e0;
            seqOut{k} = seq0;
            break;
        end
    end
    eRemain(seq0)=false;
    eOut{k} = e0;
    seqOut{k} = seq0;
end
end

