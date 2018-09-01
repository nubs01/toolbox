function out = extractMyData(animIDs,varargin)
    projDir = '~/Projects/';
    if ~exist('animIDs','var') || isempty(animIDs)
        animIDs = {'RW9','RW10','RZ9','RZ10'};
    end

    assignVars(varargin)

    % Create list of data directories
    exDirs = cell(1,numel(animIDs));
    for k=1:numel(animIDs)
        animDat = getAnimMetadata(animIDs{k});
        exDirs{k} = [projDir animDat.project filesep animDat.experiment_dir filesep animDat.animal filesep];
        exDirs{k} = strrep(exDirs{k},[filesep filesep],filesep);
    end

    % Get extraction data structure
    [exDat,exPath] = getTrexDat([],exDirs);

    % Assign Configs to extraction data
    for k=1:numel(exDat)
        searchStr = [fileparts(fileparts(fileparts(exDat(k).day_dir))) filesep '*Extraction*.trodesconf'];
        cl = subdir(searchStr);
        if isempty(cl)
            error('No Possible Configs found for %s',exDat(k).animal_name)
        end
        cn = cell(numel(cl),1);
        for l=1:numel(cl)
            [~,cn{l}] = fileparts(cl(l).name);
        end
        T = table((1:numel(cn))',cn,'VariableNames',{'Num','Config'});
        fprintf('Please Choose Config for %s Day %s: \n',exDat(k).animal_name,exDat(k).day_name)
        disp(T)
        q = input('Choice :  ');
        exDat(k).config = cl(q).name;
    end

    % Edit extraction path
    edit = true;
    while edit
        fprintf('Current Extraction Path: \n\n')
        disp(table((1:numel(exPath))',exPath','VariableNames',{'Num','Step'}))
        q = input('Would you like to edit this path? (y/n)  ','s');
        if strcmpi(q,'y')
            rmv = input('Enter step to remove:  ');
            exPath(rmv) = [];
        elseif strcmpi(q,'n')
            edit = false;
        end
    end

    % Get max possible parallel jobs
    c = parcluster(parallel.defaultClusterProfile);
    mw = c.NumWorkers;

    % Run Extraction
    fprintf('Running TREX...\n')
    out = RN_runTREXpath(exPath,exDat,mw);
