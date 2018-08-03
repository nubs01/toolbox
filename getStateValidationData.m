function out = getStateValidationData(animID,sessionNum,epochNum,varargin)
    % out = gatherStateScoringData(animID,sessionNum,varargin)
    % Gets all data needed to load a manual state verification GUI for state Scoring (stateValidationGUI)
    % out struct:
    %   - animal
    %   - day
    %   - epoch
    %   - epoch_type
    %   - riptets
    %   - specgram : Binned CWT spectrogram
    %   - spec_time
    %   - spec_freq
    %   - emg_power
    %   - emg_time
    %   - velocity
    %   - vel_time
    %   - state_mat : if states file does not exist then this will create a stateMat 
    %           TODO: For now make it just a matrix of sleep and wake times (call all sleep NREM and all wake Active)
    % Requires that animal data is in an animal metadata database
    % NAME-VALUE Pairs
    % projDir      : base directory for projects on machine (defaults for StealtElf)
    % dbPath       : path to animal metadata database (Defaults for StealthElf)
    
    projDir = '~/Projects/';
    dbPath = [projDir 'rn_Schizophrenia_Project/metadata' filesep 'animal_metadata.mat'];
    stateNames = {'REM','NREM','Rest','Active','Transition','Artifact'};
    % bandPowerWinSize = 2; % sec
    % bandPowerStep =  0.5; % sec
    % emgWinSize = 0.5; % sec 
    % emgStep = 0.1; % sec
    velFs = 25; % Hz
    %grabBands = {[1 4],[5 10],[10 14]};
    %bandNames = {'Delta','Theta','Sigma'};

    assignVars(varargin)
    fprintf('Gathering data for %s day %02i epoch %02i...\n',animID,sessionNum,epochNum)

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
    dataDir = [projDir animDat.project filesep animDat.experiment_dir filesep animID '_direct' filesep];
    dataDir = strrep(dataDir,[filesep filesep],filesep);

    recDat = animDat.recording_data(sessionNum);
    epoDat = recDat.epochs(epochNum);

    riptets = find([recDat.tet_info.riptet]);
    emgNum = find([recDat.tet_info.emg]);
    if isempty(emgNum)
        fprintf('No EMG for %s day %s.\n',animID,sessionNum);
    end

    % get all relvant file names (pos, spectra, states (if exists), emg)
    posFile = sprintf('%s%spos%02i.mat',dataDir,animID,sessionNum);
    
    specFiles = arrayfun(@(x) sprintf('%sSpectrograms%s%scwtspecgram%02i-%02i-%02i.mat',dataDir,filesep,animID,sessionNum,epochNum,x),riptets,'UniformOutput',false);
    emgFile = sprintf('%sEMG%s%semg%02i-%02i-%02i.mat',dataDir,filesep,animID,sessionNum,epochNum,emgNum);
    artFile = sprintf('%sArtifacts%s%sartifacts%02i-%02i.mat',dataDir,filesep,animID,sessionNum,epochNum);
    stateFile = sprintf('%s%sstates%02i.mat',dataDir,animID,sessionNum);
    
    fprintf('   - Getting Pos Data...\n')
    pos = load(posFile);
    pos = pos.pos{sessionNum}{epochNum};
    velCol = strcmpi(strsplit(pos.fields,' '),'vel');
    timeCol = strcmpi(strsplit(pos.fields,' '),'time');
    [velVec,velTime] = cleanVelocity(pos.data(:,velCol),pos.data(:,timeCol),'newFs',velFs);
    
    if ~isempty(emgNum)
        fprintf('   - Getting EMG Data...\n')
        emg = load(emgFile);
        emg = emg.emg{sessionNum}{epochNum}{emgNum};
        tmpT = emg.starttime:1/emg.samprate:emg.endtime;
        [emgVec,emgTime] = processRawEMG(emg.data,tmpT,emg.samprate);
    else
        emgTime = velTime;
        emgVec = zeros(size(emgTime));
    end

    fprintf('   - Loading Artifacts...\n')
    artifacts = load(artFile);
    artifacts = artifacts.artifacts{sessionNum}{epochNum};
    artTimes = artifacts.artifact_times;
    stateIdx = @(x) find(strcmpi(stateNames,x));
    if exist(stateFile,'file')
        fprintf('   - Getting existing State Data...\n')
        states = load(stateFile);
        states = states.states{sessionNum}{epochNum};
        % renumber to match stateNames numbering used in GUI & to incorporate artifacts
        tmpSN = {states.states.state};
        mapArr = zeros(numel(tmpSN));
        for k=1:numel(tmpSN)
            switch tmpSN{k}
                case {'sleeping','NREM'}
                    mapArr(k) = stateIdx('NREM');
                case {'resting','Rest'}
                    mapArr(k) = stateIdx('Rest');
                case {'moving','Active'}
                    mapArr(k) = stateIdx('Active');
                case 'REM'
                    mapArr(k) = stateIdx('REM');
                case 'Transition'
                   mapArr(k) = stateIdx('Transition');
                case 'Artifact'
                   mapArr(k) = stateIdx('Artifact');
            end
        end
        stateMat = states.state_mat;
        tmpSM = stateMat;
        tmp = stateMat(:,3)==0;
        tmpSM(tmp,3) = stateIdx('Transition');
        tmpSM(~tmp,3) = mapArr(stateMat(~tmp,3));
        stateMat = tmpSM;
    else
        fprintf('   - Creating new State Data...\n')
        states = getSleepWakeStates(emg,pos);
        stateMat = states.state_mat;
        tmpSM = stateMat;
        tmpSM(stateMat(:,3)==0,3) = stateIdx('Transition');
        tmpSM(stateMat(:,3)==1,3) = stateIdx('NREM');
        tmpSM(stateMat(:,3)==2,3) = stateIdx('Active');
        stateMat = tmpSM;
    end
    % Mark artifacts
    artIdx = getOverlapIndices(stateMat,artTimes);
    stateMat(artIdx,3)= stateIdx('Artifact');

    % Get Riptet spectrograms
    specgrams = cell(1,numel(riptets));
    specTime = [];
    specFreq = [];

    fprintf('   - Getting Spectrograms for riptets...\n')
    for k=1:numel(riptets)
        cwtspecgram = load(specFiles{k});
        cwtspecgram = cwtspecgram.cwtspecgram{sessionNum}{epochNum}{riptets(k)};
        specgrams{k} = cwtspecgram.spectrogram;
        if isempty(specTime)
            specTime = cwtspecgram.window_centers;
            specFreq = cwtspecgram.frequency;
        end
    end

    % Set output
    out.animal = animID;
    out.day = sessionNum;
    out.epoch = epochNum;
    out.epoch_type = epoDat.epoch_type;
    out.riptets = riptets;
    out.specgram = specgrams;
    out.spec_time = specTime;
    out.spec_freq = specFreq;
    out.emg_power = emgVec;
    out.emg_time = emgTime;
    out.velocity = velVec;
    out.vel_time = velTime;
    out.state_mat = stateMat;
    fprintf('Done!\n')
