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
    
    projDir = '~/Projects/';
    dbPath = [projDir 'rn_Schizophrenia_Project/metadata' filesep 'animal_metadata.mat'];
    % bandPowerWinSize = 2; % sec
    % bandPowerStep =  0.5; % sec
    % emgWinSize = 0.5; % sec 
    % emgStep = 0.1; % sec
    % velFs = 25; % Hz
    grabBands = {[1 4],[5 10],[10 14]};
    bandNames = {'Delta','Theta','Sigma'};

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
    nEpochs = numel(recDat);
    epochNames = {recDat.epochs.epoch_type}';
    epochNums = [recDat.epochs.epoch]';

    riptets = find([recDat.tet_info.riptet]);
    emgNum = find([recDat.tet_info.emg]);
    if isempty(emgNum)
        fprintf('No EMG for %s day %s.\n',animID,sessionNum);
    end



    % get all relvant file names (pos, spectra, states (if exists), emg)
    posFile = sprintf('%s%spos%02i.mat',dataDir,animID,sessionNum);
    
    specFiles = arrayfun(@(y) arrayfun(@(x) sprintf('%sSpectra%s%sspectra%02i-%02i-%02i.mat',dataDir,filesep,animID,sessionNum,y,x),riptets,'UniformOutput',false),epochNums,'UniformOutput',false);
    
    fprintf('  - Getting pos data...\n')
    pos = load(posFile);
    pos = pos.pos;
    
    for k=1:nEpochs
        ee = epochNums(k);
        fprintf('  - Processing epoch %02i...\n',ee);
        out(k).animal = animID;
        out(k).day = sessionNum;
        out(k).epoch = ee;
        out(k).epoch_type = epochNames{k};
        out(k).pos = pos{sessionNum}{ee};
        if isempty(emgNum)
           emg = [];
        else
            fprintf('      - Getting EMG data...\n');
            emgFile = sprintf('%sEMG%s%semg%02i-%02i-%02i.mat',dataDir,filesep,animID,sessionNum,ee,emgNum);
            emg = load(emgFile);
            emg = emg.emg{sessionNum}{ee}{emgNum};
        end 
        out(k).emg = emg;

        % get artifact times
        fprintf('       - Getting Artifact data...\n');
        artFile = sprintf('%sArtifacts%s%sartifacts%02i-%02i.mat',dataDir,filesep,animID,sessionNum,ee);
        artifacts = load(artFile);
        artifacts = artifacts.artifacts{sessionNum}{ee};
        out(k).artifact_times = artifacts.artifact_times;

        % grab delta, theta & sigma power bands
        bandPowers = cell(1,numel(riptets));
        bandErrors = cell(1,numel(riptets));
        cwtBandPower = cell(1,numel(riptets));
        cwtBandError = cell(1,numel(riptets));
        cwtSpec = cell(1,numel(riptets));
        specT = [];
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
            cwtSpec{l} = tmpCWT.spectrogram;
            if isempty(psdFreq)
                psdFreq = tmpCWT.frequency;
                psdTime = tmpCWT.window_centers;
            end

            fprintf('       - Getting band power for tetrode %02i...\n',tt);
            % Get band power from chronux spectra
            spectra = load(specFiles{k}{l});
            spectra = spectra.spectra{sessionNum}{ee}{tt};
            specgram = spectra.windowed_spectra;
            if isempty(specT)
                specT = spectra.window_centers;
            end
            freqVec = spectra.frequency;
            bandPowers{l} = zeros(numel(specT),numel(bandNames));
            for m=1:numel(bandNames)
                tmpIdx = freqVec>=grabBands{m}(1) & freqVec<=grabBands{m}(2);
                % Get band power from chronux spectra
                bP = mean(specgram(tmpIdx,:));
                bE = std(specgram(tmpIdx,:));
                bandPowers{l}(:,m) = bP';
                bandErrors{l}(:,m) = bE';

                % Get and power from cwt spec
                tmpIdx = psdFreq >=grabBands{m}(1) & psdFreq<=grabBands{m}(2);
                tmpBand = cwtSpec{l}(tmpIdx,:);
                cwtBandPower{l}(:,m) = mean(tmpBand)';
                cwtBandError{l}(:,m) = std(tmpBand)';
            end
        end
        out(k).cwt_spectrogram = cwtSpec;
        out(k).spec_time = psdTime;
        out(k).spec_freq = psdFreq;
        out(k).cwt_band_power = cwtBandPower;
        out(k).cwt_band_error = cwtBandError;
        out(k).band_powers = bandPowers;
        out(k).band_errors = bandErrors;
        out(k).band_time = specT;
        out(k).band_freqs = grabBands;
        out(k).band_names = bandNames;
        out(k).riptets = riptets;

    end
