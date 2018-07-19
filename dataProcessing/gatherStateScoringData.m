 function out = gatherStateScoringData(animID,sessionNum,varargin)
     % Gathers data needed manually scoring behavioral state
     % EMG, Velocity, Spectral Power, existing State Scoring,
     % LFP from CA1 tetrodes
     % Data will be binned into winSize windows for scoring (default = 2s)
     % Requires that animal data is in an animal metadata database
     % out = gatherStateScoringData(animID,sessionNum,varargin)
     % NAME-VALUE Pairs
     % projDir      : base directory for projects on machine (defaults for StealtElf)
     % dbPath       : path to animal metadata database (Defaults for StealthElf)
     % winSize      : size of window to bin data with
     
     projDir = '~/Projects/';
     dbPath = [projDir 'metadata' filesep 'animal_metadata.mat'];
     winSize = 2; % seconds

     assignVars(varargin)

     animDat = getAnimMetadata(animID,dbPath);
     if isempty(animDat)
         fprintf('No data for %s could be found in metadatabase!\n',animID);
         out = [];
         return;
     end
     if numel(animDat.recording_data)<sessionNum
         out = [];
         fprintf('No recording metadata for day %02i\n',sessionNum);
         return;
     end
     recDat = animDat.recording_data(sessionNum);
     nEpochs = numel(recDat);
     epochNames = {recDat.epochs.epoch_type}';
     epochNums = [recDat.epochs.epoch]';
     epochLabels = strcat(num2str(epochNums),':',epochNames);

     riptets = find([recDat.tet_info.riptet]);
     emgNum = find([recDat.tet_info.emg])

     dataDir = [projDir animDat.project filesep animDat.experiment_dir filesep];
     dataDir = strrep(dataDir,[filesep filesep],filesep);

     % get all relvant file names (pos, spectra, states (if exists), emg)
     posFile = sprintf('%s%spos%02i.mat',dataDir,animID,sessionNum);
     emgFiles = arrayfun(@(y) arrayfun(@(x) sprintf('%sEMG%s%semg%02i-%02i-%02i.mat',dataDir,filesep,animID,sessionNum,y,x),emgNum,'UniformOutput',false),epochNums,'UniformOutput',false);
     specFiles = arrayfun(@(y) arrayfun(@(x) sprintf('%sSpectra%s%sspectra%02i-%02i-%02i.mat',dataDir,filesep,animID,sessionNum,y,x),riptets,'UniformOutput',false),epochNums,'UniformOutput',false);
     stateFile = sprintf('%s%sstates%02i.mat',dataDir,animID,sessionNum);
     
     % Load data
     if ~exist(stateFile,'file')
         states = [];
         existingStates = 0;
     else
         existingStates = 1;
         states = load(stateFile);
         states =states.states;
     end
     pos = load(posFile);
     pos = pos.pos;
     
     for k=1:nEpochs
         out(k).epoch_type =  epochNames{k};
         out(k).epoch_label = epochLabels{k};
         velCol = strcmpi(strsplit(pos{sessionNum}{k}.fields,' '),'vel');
         timeCol = strcmpi(strsplit(pos{sessionNum}{k}.fields,' '),'time');
         [tmpVel,tmpVT] = cleanVelocity(pos{sessionNum}{k}.data(:,velCol),pos{sessionNum}{k}.data(:,timeCol));
         


