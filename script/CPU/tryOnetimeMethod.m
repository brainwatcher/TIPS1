function D = tryOnetimeMethod(D0,area,method)
if method==0
        D = max(D0);
else
        D = dot(D0.^method,area)/sum(area);
end
end