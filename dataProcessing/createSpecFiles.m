function createSpecFiles(dataDir,animID,sessionNum,varargin)

    epochSpecFreqRange = [0 120]; %Hz
    %windowSpecFreqRange = [0 60]; %Hz
    winSize = 2; % seconds
    step  = .5; % seconds
    nboot = 10000;
    overwrite = false;

    assignVars(varargin)

    eegDir = [dataDir filesep 'EEG' filesep];
    artDir = [dataDir filesep 'Artifacts' filesep];
    saveDir = [dataDir filesep 'Spectra' filesep];
    if ~exist(saveDir,'dir')
        mkdir(saveDir)
    end

    eegFiles = dir(sprintf('%s%seeg%02i-*-*.mat',eegDir,animID,sessionNum));
    eegFiles = {eegFiles.name};

    for k=1:numel(eegFiles)
        parsed = parseDataFilename(eegFiles{k},animID);
        ee = str2double(parsed.epoch);
        tt = str2double(parsed.tet);
        saveFile = sprintf('%s%sspectra%02i-%02i-%02i.mat',saveDir,animID,sessionNum,ee,tt);
        if exist(saveFile,'file') && ~overwrite
            fprintf('Spectra file for day %02i epoch %02i tet %02i already exists. Skipping...\n',sessionNum,ee,tt)
            continue;
        end
        fprintf('Creating spectra file for %s day %02i epoch %02i tetrode %02i...\n',animID,sessionNum,ee,tt);
        eeg = load([eegDir eegFiles{k}]);
        eeg = eeg.eeg{sessionNum}{ee}{tt};

        params = struct('tapers',[3 4],'Fs',eeg.samprate,'fpass',epochSpecFreqRange);
        [Pxx,t,Fx] = mtspecgramc(eeg.data,[winSize step],params); % each column of Pxx is a frequency band
        t = t+eeg.starttime;
        winTimes = [t'-winSize/2 t'+winSize/2];

        % remove windows with artifacts
        artFile = sprintf('%s%sartifacts%02i-%02i.mat',artDir,animID,sessionNum,ee);
        if ~exist(artFile,'file')
            disp('Artifact file does not exist. Not excluding artifacts.')
            Pxx2 = Pxx;
            artWins = [];
            artExcluded = 0;
            artFile = '';
        else
            artifacts = load(artFile);
            artifacts = artifacts.artifacts{sessionNum}{ee};
            artWins = getOverlapIndices(winTimes,artifacts.artifact_times);
            Pxx2 = Pxx;
            Pxx2(artWins,:) = [];
            artExcluded = 1;
        end
        bootdat = bootstrapDat(Pxx,nboot);
        meanEpoSpec = [bootdat.mean];
        epoSpecError = [bootdat.SEM];

        specStruct.epoch_spectrum = meanEpoSpec;
        specStruct.epoch_spectrum_error = epoSpecError;
        specStruct.frequency = Fx;
        specStruct.windowed_spectra = Pxx';
        specStruct.window_times = winTimes;
        specStruct.window_centers = t;
        specStruct.window_size = winSize;
        specStruct.artifact_windows = artWins;
        specStruct.artifacts_excluded = artExcluded;
        specStruct.artifact_filename = artFile;

        spectra = cell(1,sessionNum);
        spectra{sessionNum} = cell(1,ee);
        spectra{sessionNum}{ee} = cell(1,tt);
        spectra{sessionNum}{ee}{tt} = specStruct;
        save(saveFile,'spectra');
    end


