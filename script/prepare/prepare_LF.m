function [Data,mesh] = prepare_LF(dataRoot,subMark,cfg)
inputFilePath = fullfile(dataRoot,subMark,'TI_sim_result',cfg.type);
if ~exist(inputFilePath ,'dir')
    mkdir(inputFilePath );
end
inputFile = fullfile(inputFilePath,['input' cfg.type '.mat']);
%%
if exist(inputFile,'file')
    disp('Already existed input data for GPU, omit producing input mat file.');
    S = load(inputFile);
    Data = S.Data;
else
    disp('The first time prepare input data for GPU.');
    disp(['Element type is ' cfg.type ' ...']);
    t0 = tic;
    switch cfg.type
        case 'tri'
            [Data,mesh] = LFSurf(dataRoot,subMark);
        case 'tet'
            [Data,mesh] = LFTet(dataRoot,subMark);
    end
    save(inputFile,'Data','mesh','-v7.3');
    disp(['Prepare with ' cfg.type ' type using ' num2str(toc(t0)) 'seconds.']);
end