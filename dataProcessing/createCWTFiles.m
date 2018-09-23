function createCWTFiles(dataDir,animID,sessionNum,varargin)

    freqRange = [0 30]; %Hz
    winSize = 1; % seconds
    step  = .5; % seconds
    freqRes = 0.25;

    assignVars(varargin)

    eegDir = [dataDir filesep 'EEG' filesep];
    saveDir = [dataDir filesep 'Spectrograms' filesep];
    if ~exist(saveDir,'dir')
        mkdir(saveDir)
    end

    eegFiles = dir(sprintf('%s%seeg%02i-*-*.mat',eegDir,animID,sessionNum));
    eegFiles = {eegFiles.name};

    for k=1:numel(eegFiles)
        parsed = parseDataFilename(eegFiles{k},animID);
        ee = str2double(parsed.epoch);
        tt = str2double(parsed.tet);
        saveFile = sprintf('%s%scwtspecgram%02i-%02i-%02i.mat',saveDir,animID,sessionNum,ee,tt);
        if exist(saveFile,'file')
            fprintf('Spectra file for day %02i epoch %02i tet %02i already exists. Skipping...\n',sessionNum,ee,tt)
            continue;
        end
        fprintf('Creating spectrogram file for %s day %02i epoch %02i tetrode %02i...\n',animID,sessionNum,ee,tt);
        eeg = load([eegDir eegFiles{k}]);
        eeg = eeg.eeg{sessionNum}{ee}{tt};
        fs = eeg.samprate;
        [psd,f,t] = getBinnedCWTSpectrogram(eeg.data,fs,winSize*fs,'freqRange',freqRange,'freqRes',freqRes);
        t = t+eeg.starttime;
        if isrow(t)
            t = t';
        end
        winTimes = [t-winSize/2 t+winSize/2];

        specStruct.frequency = f;
        specStruct.spectrogram = psd;
        specStruct.window_times = winTimes;
        specStruct.window_centers = t;
        specStruct.window_size = winSize;
        specStruct.window_step = step;

        cwtspecgram = cell(1,sessionNum);
        cwtspecgram{sessionNum} = cell(1,ee);
        cwtspecgram{sessionNum}{ee} = cell(1,tt);
        cwtspecgram{sessionNum}{ee}{tt} = specStruct;
        save(saveFile,'cwtspecgram');
    end


