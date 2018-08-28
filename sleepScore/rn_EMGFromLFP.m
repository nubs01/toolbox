function out = rn_EMGFromLFP(animID,dataDir,sessionNum,varargin)

    filterFile = 'EMGFromLFP_filter.mat';
    Hd =  load(filterFile);
    lfpFilter = Hd.Hd;
    emgFs = 2; %Hz
    overwrite = true;
    corrChunkSz = 20;

    assignVars(varargin)

    % Grab animal metadata
    animDat = getAnimMetadata(animID);
    if isempty(animDat.recording_data)
        disp(['No recording data found for ' animID])
        return;
    end
    recDat = animDat.recording_data(sessionNum);
    tetInfo = recDat.tet_info;

    % figure out which tets to use (all except exclude)
    % requirements: not EMG, lfp_channel~=0, not exclude
    validTets = find(([tetInfo.lfp_channel]>0 & ~[tetInfo.exclude] & ~[tetInfo.emg]));
    epochs = 1:numel(recDat.epochs);

    % Setup data and save directories
    eegDir = [dataDir filesep 'EEG' filesep];
    emgDir = [dataDir filesep 'EMG' filesep];
    saveFile = @(x) sprintf('%s%semgfromlfp%02i-%02i.mat',emgDir,animID,sessionNum,x);
    eegFile = @(x,y) sprintf('%s%seeg%02i-%02i-%02i.mat',eegDir,animID,sessionNum,x,y);
    out = cell(numel(epochs),1);
    for ee=epochs
        if exist(saveFile(ee),'file') && ~overwrite
            fprintf('emffromlfp file already exists for %s Day %02i Epoch %02i. Skipping...\n',animID,sessionNum,ee)
            continue;
        elseif  exist(saveFile(ee),'file')
            fprintf('emffromlfp file already exists for %s Day %02i Epoch %02i. Overwriting...\n',animID,sessionNum,ee)
        end

        % grab LFP traces
        eegTime = [];
        tStart = [];
        Fs = nan;
        eegTraces = cell(1,max(validTets));
        for tt=validTets
            eeg = load(eegFile(ee,tt));
            eeg = eeg.eeg{sessionNum}{ee}{tt};
            if isempty(eegTime)
                eegTime = eeg.starttime:1/eeg.samprate:eeg.endtime;
                Fs = eeg.samprate;
            end
            lfp = eeg.data;
            % Filter LFP  at [275 300 600 625] (default filter is 125th order
            % dual bandpass filter created with filterDesign)
            filtLFP = filter(lfpFilter,lfp);
            eegTraces{tt} = filtLFP;
        end

        % make bins
        binStep = 1/emgFs;
        binStepPts = round(binStep*Fs);
        win_inds = -binStepPts:binStepPts;
        timestamps = (1+binStepPts):binStepPts:(numel(eegTime)-binStepPts);
        nBins = numel(timestamps);
        EMGCorr = zeros(nBins,1);

        % get total correlation for emg pairs
        tetPairs = nchoosek(validTets,2);
        for k=1:size(tetPairs,1)
            c1 = [];
            c2 = [];
            binind = 0;
            binindstart = 1;
            for l=timestamps
                binind = binind+1;
                s1 = eegTraces{tetPairs(k,1)}(l + win_inds);
                s2 = eegTraces{tetPairs(k,2)}(l + win_inds);
                c1 = cat(2,c1,s1);
                c2 = cat(2,c2,s2);
                if size(c1,2) == corrChunkSz || l==timestamps(end)
                    binindend = binind;
                    tmp = corr(c1,c2);
                    tmp = diag(tmp);
                    EMGCorr(binindstart:binindend) = EMGCorr(binindstart:binindend) + tmp;
                    c1 = [];
                    c2 = [];
                    binindstart = binind+1;
                end
            end
        end

        % Normalize
        EMGCorr = EMGCorr./size(tetPairs,1);

        % make save struct
        corrTime = timestamps./Fs + eegTime(1);
        tmpStruct.descript = 'EMG derived from high-frequency correlations between tetrode LFPs';
        tmpStruct.derivation_function = 'rn_EMGFromLFP';
        tmpStruct.timerange = [eegTime(1) eegTime(end)];
        tmpStruct.starttime = corrTime(1);
        tmpStruct.endtime = corrTime(end);
        tmpStruct.time = corrTime;
        tmpStruct.samprate = emgFs;
        tmpStruct.tetrodes_used = validTets;
        tmpStruct.data = EMGCorr;
        tmpStruct.referenced = 0;
        tmpStruct.filter = lfpFilter;
        emgfromlfp = cell(1,sessionNum);
        emgfromlfp{sessionNum} = cell(1,ee);
        emgfromlfp{sessionNum}{ee} = tmpStruct;
        save(saveFile(ee),'emgfromlfp')
        out{ee} = tmpStruct;
    end


    

