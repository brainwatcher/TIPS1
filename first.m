%% addPath
root = pwd;
codepath = fullfile(root,'script');
addpath(genpath(codepath));
disp('add path success...');
%% leadfield data
dataRoot = fullfile(pwd,'data','HipTest');
prepareROI(dataRoot);
prepareCortex(dataRoot);
disp('prepare data success...');
%% gpu compile
cd(fullfile(codepath,'CUDA'));
compileTI('ROI');
compileTI('Cortex');
compileTI('Elec6');
compileTI('Elec8');
% compile('ROIMax');
% compile('CortexMax');
% compile('ROIMean');
% compile('CortexMean');
cd(root);
disp('Cuda Mex all success...');