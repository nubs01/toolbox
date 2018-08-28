function SleepStateEpisodes = StatesToEpisodes(sleepStates,varargin)

    % Episode Parameters - defaults from  Buzsaki sleep Scoreing code
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

    v2struct(epWinParams)

    NREMints = sleepStates.NREMints;
    REMints = sleepStates.REMints;
    WAKEints = sleepStates.WAKEints;

    NREMlengths = diff(NREMints,1,2);
    WAKElengths = diff(WAKEints,1,2);
    packetintervals = NREMints(NREMlengths>=minPacketDuration);
    MAintervals = WAKEints(WAKElengths<=maxMicroarousalDuration);
    WAKEintervals = WAKEints(WAKElengths>maxMicroarousalDuration,:);

    episodeintervals{1} = IDStateEpisodes(WAKEints,maxWAKEEpisodeInterruption,minWAKEEpisodeDuration);
    episodeintervals{2} = IDStateEpisodes(NREMints,maxNREMEpisodeInterruption,minNREMEpisodeDuration);
    episodeintervals{3} = IDStateEpisodes(REMints,maxREMEpisodeInterruption,minREMEpisodeDuration);

    origNREM = episodeintervals{2};
    newNREM = [];

    % Get NREM episodes with REM inside
    REMints  = sortrows(REMints);
    NREMwREMinside = find(origNREM(:,1)<=REMints(:,1) && REMints(:,1)<=origNREM(:,2));
    badNREM = unique(NREMwREMinside);
    for k = badNREM'
        thisInt = origNREM(k,:);
        remInside = find(REMints(:,1)>=thisInt(1) & REMints(:,1)<=thisInt(2));
        origNREM(k,:) = [];

        for l = remInside'
            newNREM = [newNREM;thisInt(1) REMints(l,1)];
            thiInt = [REMints(l,2) thisInt(2)];
        end
    end
    newNREM = [newNREM;thisInt];
    NREMepisodes = [origNREM;newNREM];
    NREMepisodes = sortrows(NREMepisodes);
    NREMepisodes(diff(NREMepisodes,1,2)<minNREMEpisodeDuration,:) = [];
    episodeintervals{2} = NREMepisodes;

    % Identify MAs preceeding REM and separate them into MA_REM
    %Find the MA states that are before (or between two) REM states
    [ ~,~,MAInREM,~ ] = FindIntsNextToInts(MAIntervals,REMints);
    %"Real" MAs are those that are not before REM state
    realMA = setdiff(1:size(MAIntervals,1),MAInREM);
    
    MAInREM = MAintervals(MAInREM,:);
    MAintervals = MAintervals(realMA,:);

    % Output
    SleepStateEpisodes.state_names = {'wake','nrem','rem'};
    SleepStateEpisodes.WAKEepisodes = episodeintervals{1};
    SleepStateEpisodes.NREMepisodes = episodeintervals{2};
    SleepStateEpisodes.REMepisodes = episodeintervals{3};
    SleepStateEpisodes.NREMpackets = packetintervals;
    SleepStateEpisodes.MA = MAintervals;
    SleepStateEpisodes.MA_REM = MAInREM;
    SleepStateEpisodes.detection_params = epWinParams;
    SleepStateEpisodes.decetion_date = datetime('Now');
    SleepStateEpisodes.detector = sleepStates.detector;
    
    stateMat = [];
    for k=1:3
        tmp = [episodeintervals{k} repmat(k,size(episodeintervals{k},1),1)];
        stateMat = [stateMat;tmp];
    end
    stateMat = sortrows(stateMat);
    SleepStateEpisodes.state_mat = stateMat;


