function out = scoreStates(animID,dataDir,sessionNum,varargin)

    animDat = getAnimMetadata(animID);
    if isempty(animDat.recording_data)
        error('No recording metadata found for %s',animID)
    end


    % Min Window Parameters
    minSWsecs = 6;
    minWAKEsecs = 6;
    minREMsecs = 6;
    minREMinWsecs = 6;
    minWinREMsecs = 6;
    minWnexttoREMsecs = 6;
    minWinParams = v2struct(minSWsecs,minWAKEsecs,minREMsecs,...
        minREMinWsecs,minWinREMsecs,minWnexttoREMsecs);

    % Episode Parameters
    minPacketDuration = 20;
    minWAKEEpisodeDuration = 20;
    minNREMEpisodeDuration = 20;
    minREMEpisodeDuration = 20;

    maxMicroarousalDuration = 100;

    maxWAKEEpisodeInterruption = 40;
    maxNREMEpisodeInterruption = maxMicroarousalDuration;
    maxREMEpisodeInterruption = 40;
    epWinParams = v2struct(minPacketDuration,minWAKEEpisodeDuration,...
        minNREMEpisodeDuration,minREMEpisodeDuration,...
        maxMicroarousalDuration,maxWAKEEpisodeInterruption,...
        maxNREMEpisodeInterruption,maxREMEpisodeInterruption);

    overwrite = false;

    assignVars(varargin)

    out = [];
    recDat = animDat.recording_data(sessionNum);
    nEpochs = numel(recDat.epochs);
    epochNums = [recDat.epochs.epoch];
    states = cell(1,sessionNum);
    states{sessionNum} = cell(1,nEpochs);
    if dataDir(end)==filesep
        dataDir = dataDir(1:end-1);
    end
    figDir = [fileparts(dataDir) filesep animID '_analysis' filesep];
    stateDir = sprintf('%s%sSleepStates%s',dataDir,filesep,filesep);
    saveFile = sprintf('%s%sstates%02i.mat',stateDir,animID,sessionNum);
    if ~exist(stateDir,'dir')
        mkdir(stateDir)
    end
    if exist(saveFile,'file')
        if ~exist('overwrite','var')
            q = input('Sleep State File Already Exists. Overwrite (Y/N):  ','s');
            if strcmpi(q,'n')
                return
            end 
        elseif ~overwrite
            fprintf('State File already exists. Skipping...\n')
            return;
        end
    end
    for epochNum = epochNums

        % Get animal scoring data
        scoreData = gatherBuzsakiStateScoringData(animID,sessionNum,epochNum);

        % Get sleep states from EMG, Slow-Wave, & Theta LFP channels
        fprintf('    - Clustering States...\n')
        sleepStates = ClusterStates(scoreData,'minWinParams',minWinParams);
        fprintf('    - Converting to Episodes...\n')
        SleepStateEpisodes = StatesToEpisodes(sleepStates,'epWinParams',epWinParams);

        % Save data
        states{sessionNum}{epochNum} = SleepStateEpisodes;

        % Plot Histograms and Thresholds
        HnT = SleepStateEpisodes.histandthreshs;
        f1 = figure('Position',[681 273 845 680]);
        subplot(2,2,1:2)
        bar(HnT.swHistBins,HnT.swHist,'b');
        hold on
        yl = get(gca,'YLim');
        plot([1 1]*HnT.swThresh,yl,'r','LineWidth',2)
        ylabel('Counts')
        xlabel('Norm Power')
        title(sprintf('Broadband Slow Wave: Tet %02i',SleepStateEpisodes.swTet))
        subplot(2,2,3)
        bar(HnT.emgHistBins,HnT.emgHist,'m');
        hold on
        yl = get(gca,'YLim');
        plot([1 1]*HnT.emgThresh,yl,'r','LineWidth',2)
        ylabel('Counts')
        xlabel('Norm Power')
        title('EMG Power: derived from LFP')
        subplot(2,2,4)
        bar(HnT.thHistBins,HnT.thHist,'c')
        hold on
        yl = get(gca,'YLim');
        plot([1 1]*HnT.thThresh,yl,'r','LineWidth',2)
        title(sprintf('Theta Ratio: Tet %02i',SleepStateEpisodes.thTet))
        suptitle(sprintf('Sleep State Thresholding: %s, Day %02i Epoch %02i',animID,sessionNum,epochNum))

        figFile = sprintf('%s%s_SleepStateThreshs%02i-%02i',figDir,animID,sessionNum,epochNum);
        saveas(f1,figFile,'png')

        % Detect Spindles and Slow Waves

    end
    save(saveFile,'states')
    out = states;
