function [outputArg1,outputArg2] = elec6Step(inputArg1,inputArg2)
%ELEC6 Summary of this function goes here
%   Detailed explanation goes here
% %% step3. Elec6
% k6_in = 100;
% k6_out = 100;
% if(k6_in>size(T2,1))
%     error('Not enough candidate number in elec6!');
% end
% disp(['There are ' num2str(k6_in) ' candidate montage to be modified in elec6.']);
% T6a = cell(k6_in,1);
% U6a = cell(k6_in,1);
% t = tic;
% for i = 1:k6_in
%     T2i = T2(i,:);
%     U4i = T2U(T2i);
%     C0 = FreeC0([U4i.a.elec,U4i.b.elec],2);
%     Ci = [C0;C0(:,[2,1])];
%     cu6 = makeCu6(0.7,U4i);
%     [T6a{i},U6a{i}] = Elec6Shell(Nr,E_ROI_p,area_ROI_p,No,E_Other_p,area_Other_p,cfg.method_ROI,cfg.method_Other,cu6,Ci,U4i,thres,T2.Ratio(1),k6_out);
% end
% [T6,U6] = Bigk(T6a,U6a,k6_out);
% if(~isempty(T6))
%     U6m = U6{1};
%     T6m = T6(1,:);
%     showU(U6m);
%     disp(T6m);
%     T6mcpu = tryOnetime(U6m,E_ROI,E_Other,area_ROI,area_Other,cfg.method_ROI,cfg.method_Other);
%     disp('cpu check...');
%     disp(T6mcpu);
%     disp(['Elec6 : ' num2str(toc(t)) ' s...']);
%     save(fullfile(workSpace,'elec6.mat'),'T6','U6','T6m','U6m','electrodes');
%     disp(['6 elec improves ' num2str((T6m.R-T2.Ratio(1))/T2.Ratio(1)*100) '% than 4 elec montage.']);
%     Ufinal = U6m;
% else
%     disp('Elec4 to 6 has no improvement');
%     Ufinal = U4m;
end

