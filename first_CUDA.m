%% gpu compile
cd(fullfile(codepath,'CUDA'));
compileTI('ROI');
compileTI('Cortex');
compileTI('Elec6');
compileTI('Elec8');
cd(root);
disp('Cuda Mex all success...');