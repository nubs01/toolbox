function createBehavioralStateFiles(dataDir,animID,sessionNum,varargin)
    %
    %
    behavioralStates = {'sleeping','resting','moving'};
    stateVelRanges = {[0,.5],[0,.5],[.6 80]};
    stateDurationRanges = {[40 3000],[10 40],[10 3000]};
    allowedInterrupts = {0,0,2};
    stateParams = struct('state',behavioralStates,'velRange',stateVelRanges,'durRange',stateDurationRanges,'allowedInterrupt',allowedInterrupts);
    velFs = 25; % Hz, for resampling velocity & EMG envelope

    assignVars(varargin)

    posFile = sprintf('%s%s%spos%02i.mat',dataDir,filesep,animID,sessionNum);
    saveFile = sprintf('%s%s%sstates%02i.mat',dataDir,filesep,animID,sessionNum);

    if exist(saveFile,'file')
        fprintf('Behavioral state file for %s day %02i already exists. Skipping...\n',animID,sessionNum);
        return;
    end
    fprintf('Creating Behavioral State file for %s day %02i...\n',animID,sessionNum)
    emgDir = [dataDir filesep 'EMG' filesep];

    pos = load(posFile);
    pos = pos.pos;

    tmp = cellfetch(pos,'data');
    idx = tmp.index;
    epochs = unique(idx(:,2));
    nEpochs = numel(epochs);
    states = cell(1,sessionNum);
    states{sessionNum} = cell(1,nEpochs);
    vals = tmp.values;
    clear tmp

    for l=1:size(idx,1)
        ee = idx(l,2);
        emgFile = dir(sprintf('%s%semg%02i-%02i-*.mat',emgDir,animID,sessionNum,ee));
        if numel(emgFile)>1
            % TODO: handle extra EMG tetrodes
            error('more than one emg file')
        end
        if ~isempty(emgFile)
            emgFile = emgFile.name;
            emg = load([emgDir emgFile]);
            tmp = parseDataFilename(emgFile,animID);
            emg = emg.eeg{sessionNum}{ee}{str2double(tmp.tet)};
            emgTime = emg.starttime:1/emg.samprate:emg.endtime;
            emgRaw = emg.data;
            Fs = emg.samprate;
            emgEnv = envelope(emgRaw);
        else
            emgFile = '';
            emgEnv = [];
            emgTime = [];
            Fs = nan;
        end
        
        colNames = strsplit(pos{sessionNum}{ee}.fields,' ');
        velCol = find(strcmpi(colNames,'vel'));
        rawVel = vals{l}(:,velCol);
        timeCol = find(strcmpi(colNames,'time'));
        velTime = vals{l}(:,timeCol);
        [smoothVel,smoothVelTime] = cleanVelocity(rawVel,velTime,'newFs',velFs);
        
        if ~isempty(emgFile)
            emgEnv_downsamp = interp1(emgTime,emgEnv,smoothVelTime,'linear','extrap');
        else
            emgEnv_downsamp = zeros(size(smoothVel));
        end
        
        stateMat = getBehavioralEpisodes(smoothVelTime,smoothVel,stateParams);
        stateVec = zeros(1,numel(smoothVelTime));
        for m=1:numel(smoothVelTime)
            tmpIdx = find(stateMat(:,1)<=smoothVelTime(m) & stateMat(:,2)>=smoothVelTime(m));
            if ~isempty(tmpIdx)
               stateVec(m) = stateMat(tmpIdx,3);
           end
       end

        stateStruct.fields = 'time smooth_vel emg_envelope behavioral_state';
        stateStruct.states = stateParams;
        stateStruct.emg_filename = emgFile;
        stateStruct.pos_filename = posFile;
        stateStruct.samprate = velFs;
        stateStruct.orig_emg_samprate = Fs;
        stateStruct.orig_vel_samprate = 30;
        stateStruct.state_mat = stateMat;
        stateStruct.data = [smoothVelTime' smoothVel' emgEnv_downsamp' stateVec'];
        states{sessionNum}{ee} = stateStruct;
    end
    save(saveFile,'states')



    %
    % Later: Get EMG files 
    % Get Position Files
    % 
    % Later: Process EMG - Filter and Envelope
    % Process Velocity - smooth and resample
    %
    % Later: Determine Immobile periods with EMG threshold
    % Determine Immobile perdiods with Velocity
    % Resolve immobility between two 
    %
    %
    %
    % Load pos file for day
    % loop through epochs
    % get velocity
    % smooth velocity & resample
    % getBehavioralEpisodes
    % Make state vector 
