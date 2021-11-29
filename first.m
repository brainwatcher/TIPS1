%% addPath
root = pwd;
codepath = fullfile(root,'script');
addpath(genpath(codepath));
disp('add path success...');
%% gpu compile
cd(fullfile(codepath,'CUDA'));
compileTI('ROI');
compileTI('Cortex');
compileTI('Elec6');
compileTI('Elec8');
cd(root);
disp('Cuda Mex all success...');