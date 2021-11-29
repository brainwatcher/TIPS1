function inputFile = prepare_input(dataRoot,subMark,cfg)
inputFilePath = fullfile(dataRoot,subMark,'TI_sim_result',cfg.type);
if ~exist(inputFilePath ,'dir')
    mkdir(inputFilePath );
end
inputFile = fullfile(inputFilePath,'input.mat');
%%
if exist(inputFile,'file')
    disp('Already existed input data for GPU, omit producing input mat file.');
else
    disp('The first time prepare input data for GPU.');
    disp(['Element type is ' cfg.type ' ...']);
    t0 = tic;
    switch cfg.type
        case 'tri'
            [Data,gmS] = LFSurf(dataRoot,subMark);
            save(inputFile,'Data','gmS','-v7.3');
        case 'tet'
            [Data,DT,elem5] = LFTet(dataRoot,subMark);
            save(inputFile,'Data','DT','elem5','-v7.3');
    end
    disp(['Prepare with ' cfg.type ' type using ' num2str(toc(t0)) 'seconds.']);    
end