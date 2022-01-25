root = pwd;
codepath = fullfile(root,'script');
%% gpu compile
cd(fullfile(codepath,'CUDA'));
compileTI('ROI');
compileTI('Cortex');
compileTI('Elec6');
compileTI('Elec8');
compileTI('ROInt');
compileTI('Cortex_nt');
cd(root);
disp('Cuda Mex all success...');
%%