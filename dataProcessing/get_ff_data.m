function [out,out_paths] = get_ff_data(animID,dataName,varargin)

    firstStr = find(cellfun(@ischar,varargin),1,'first');
    if numel(varargin)>0 && (isempty(firstStr) || firstStr>1) 
        if isempty(firstStr)
            dayAddr = [varargin{:}];
            varargin = {};
        else
            dayAddr = [varargin{1:firstStr-1}];
            varargin = varargin(firstStr:end);
        end
    else
        dayAddr = [];
    end
    subFolder = '';
    projDir = get_data_path('project_directory');
    dbPath = get_data_path('sz_metadata');

    assignVars(varargin)

    animDat = getAnimMetadata(animID,dbPath);
    expDir = [projDir filesep animDat.project filesep animDat.experiment_dir filesep];
    dataDir = [expDir animID '_direct' filesep];
    rawDir = [expDir animID filesep];
    
    dayAddrStr = sprintf(strjoin(repmat({'%02i'},1,numel(dayAddr)),'-'),dayAddr);
    dataFile = [subFolder filesep animID dataName dayAddrStr '.mat'];

    outData = load([dataDir dataFile]);
    tmpOut = outData.(dataName);

    if ~isempty(dayAddr) 
        for k=dayAddr
            tmpOut = tmpOut{k};
        end
    end
    out = tmpOut;
    out_paths = struct('expDir',expDir,'dataDir',dataDir,'rawDir',rawDir);



