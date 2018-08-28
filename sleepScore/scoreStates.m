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
    

    assignVars(varargin)

    out = [];
    recDat = animDat.recording_data(sessionNum);
    nEpochs = numel(recDat.epochs);
    epochNums = [recDat.epochs.epoch];
    states = cell(1,sessionNum);
    states{sessionNum} = cell(1,nEpochs);
    stateDir = sprintf('%s%sSleepStates%s',dataDir,filesep,filesep);
    saveFile = sprintf('%s%sstates%02i.mat',stateDir,animID,sessionNum);
    if ~exist(stateDir,'dir')
        mkdir(stateDir)
    end
    if exist(saveFile,'file')
        q = input('Sleep State File Already Exists. Overwrite (Y/N):  ','s');
        if strcmpi(q,'n')
            return
        end
    end
    for epochNum = epochNums

        % Get animal scoring data
        scoreData = gatherBuzsakiStateScoringData(animID,sessionNum,epochNum);

        % Get sleep states from EMG, Slow-Wave, & Theta LFP channels
        sleepStates = ClusterStates(scoreData,'minWinParams',minWinParams);

        SleepStateEpisodes = StatesToEpisodes(sleepStates,'epWinParams',epWinParams);

        % Save data
        states{sessionNum}{epochNum} = SleepStateEpisodes;



        % Detect Spindles and Slow Waves

    end
    save(saveFile,'states')
    out = states;
