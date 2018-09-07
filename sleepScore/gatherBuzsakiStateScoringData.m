function out = gatherBuzsakiStateScoringData(animID,sessionNum,epochNum,varargin)
    % Gathers data needed manually scoring behavioral state
    % EMG, Velocity, Spectral Power, existing State Scoring,
    % LFP from CA1 tetrodes
    % Data will be binned into winSize windows for scoring (default = 2s)
    % Requires that animal data is in an animal metadata database
    % out = gatherStateScoringData(animID,sessionNum,varargin)
    % NAME-VALUE Pairs
    % projDir      : base directory for projects on machine (defaults for StealtElf)
    % dbPath       : path to animal metadata database (Defaults for StealthElf)
    
    projDir = '~/Projects/';
    dbPath = [projDir 'rn_Schizophrenia_Project/metadata' filesep 'animal_metadata.mat'];

    assignVars(varargin)
    fprintf('Gathering data for %s day %02i...\n',animID,sessionNum)

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

    % Get best SW and theta tetrodes
    fprintf('  - Getting best SW and theta tetrodes...\n')
    tetInfo = recDat.tet_info;
    allTets = [tetInfo.tetrode];
    valididx = strcmpi({tetInfo.target},'CA1') & ~[tetInfo.exclude] & [tetInfo.lfp_channel]~=0;
    validTets = allTets(valididx);
    swthFile = sprintf('%sBestSWTHdat%s%sswth%02i-%02i.mat',dataDir,filesep,animID,sessionNum,epochNum);
    if exist(swthFile,'file')
        swth = load(swthFile);
        swth = swth.swth{sessionNum}{epochNum};
        swDat = swth.swDat;
        thDat = swth.thDat;
    else
        [swDat,thDat] = pickSWTHlfp(animID,dataDir,sessionNum,epochNum,'validTets',validTets,'saveFigs',true);
    end
    out.swDat = swDat;
    out.thDat = thDat;


    % get all relvant file names (pos, spectra, states (if exists), emg)
    posFile = sprintf('%s%spos%02i.mat',dataDir,animID,sessionNum);
    
    fprintf('  - Getting pos data...\n')
    pos = load(posFile);
    pos = pos.pos;
    
    ee = epoDat.epoch;
    fprintf('  - Processing epoch %02i...\n',ee);
    out.animal = animID;
    out.day = sessionNum;
    out.epoch = ee;
    out.epoch_type = epoDat.epoch_type;
    out.pos = pos{sessionNum}{ee};

    % Apparently Buzsaki sleep scoring procedure only works with emg derived from lfp
    emgNum = [];
    if isempty(emgNum)
       emgFile = sprintf('%sEMG%s%semgfromlfp%02i-%02i.mat',dataDir,filesep,animID,sessionNum,ee);
       if ~exist(emgFile,'file')
           fprintf('EMGFromLFP file does not exist. Creating...\n')
           rn_EMGFromLFP(animID,dataDir,sessionNum);
       end
       emg = load(emgFile);
       emg = emg.emgfromlfp{sessionNum}{ee};
    else
        fprintf('      - Getting EMG data...\n');
        emgFile = sprintf('%sEMG%s%semg%02i-%02i-%02i.mat',dataDir,filesep,animID,sessionNum,ee,emgNum);
        emg = load(emgFile);
        emg = emg.emg{sessionNum}{ee}{emgNum};
    end 
    out.emg = emg;

    % get artifact times
    fprintf('       - Getting Artifact data...\n');
    artFile = sprintf('%sArtifacts%s%sartifacts%02i-%02i.mat',dataDir,filesep,animID,sessionNum,ee);
    artifacts = load(artFile);
    artifacts = artifacts.artifacts{sessionNum}{ee};
    out.artifact_times = artifacts.artifact_times;

        % grab delta, theta & sigma power bands
        cwtSpec = cell(1,numel(riptets));
        psdFreq = [];
        psdTime = [];
        for l=1:numel(riptets)
            tt = riptets(l);
            % Get Binned CWT Spectrogram
            cwtFile = sprintf('%sSpectrograms%s%scwtspecgram%02i-%02i-%02i.mat',...
                                dataDir,filesep,animID,sessionNum,ee,tt);
            if ~exist(cwtFile,'file')
                fprintf('       - Computing CWT spectrogram for tetrode %02i...\n',tt);
                createCWTFiles(dataDir,animID,sessionNum)
            end
            fprintf('       - Gathering CWT spectrogram for tetrode %02i...\n',tt);
            tmpCWT = load(cwtFile);
            tmpCWT = tmpCWT.cwtspecgram{sessionNum}{ee}{tt};
            cwtSpec{l} = abs(tmpCWT.spectrogram);
            if isempty(psdFreq)
                psdFreq = tmpCWT.frequency;
                psdTime = tmpCWT.window_centers;
            end
        end
        out.cwt_spectrogram = cwtSpec;
        out.spec_time = psdTime;
        out.spec_freq = psdFreq;
        out.riptets = riptets;

    end
