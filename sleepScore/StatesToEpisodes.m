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
    packetintervals = NREMints(NREMlengths>=minPacketDuration,:);
    MAintervals = WAKEints(WAKElengths<=maxMicroarousalDuration,:);
    WAKEintervals = WAKEints(WAKElengths>maxMicroarousalDuration,:);

    episodeintervals{1} = IDStateEpisodes(WAKEints,maxWAKEEpisodeInterruption,minWAKEEpisodeDuration);
    episodeintervals{2} = IDStateEpisodes(NREMints,maxNREMEpisodeInterruption,minNREMEpisodeDuration);
    episodeintervals{3} = IDStateEpisodes(REMints,maxREMEpisodeInterruption,minREMEpisodeDuration);

    episodeintervals{2} = splitAroundEpisodes(episodeintervals{2},REMints,minNREMEpisodeDuration);

    % Identify MAs preceeding REM and separate them into MA_REM
    %Find the MA states that are before (or between two) REM states
    [ ~,~,MAInREM,~ ] = findIntsNextToInts(MAintervals,REMints);
    %"Real" MAs are those that are not before REM state
    realMA = setdiff(1:size(MAintervals,1),MAInREM);
    
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
    % to create state mat first split NREM episodes around wake intervals
    episodeintervals{2} = splitAroundEpisodes(episodeintervals{2},episodeintervals{1},minNREMEpisodeDuration);
    for k=1:3
        tmp = [episodeintervals{k} repmat(k,size(episodeintervals{k},1),1)];
        stateMat = [stateMat;tmp];
    end
    stateMat = sortrows(stateMat);
    SleepStateEpisodes.state_mat = stateMat;

function out = splitAroundEpisodes(toSplit,breakEPs,minDur)
    orig = toSplit;
    newStates = [];
    breakEPs = sortrows(breakEPs);
    cutIdx = [];
    for k=1:size(toSplit,1)
        if any(toSplit(k,1)<=breakEPs(:,1) & toSplit(k,2)>=breakEPs(:,1))
            cutIdx = [cutIdx;k];
        end
    end
    cutIdx = unique(cutIdx);
    for k=cutIdx'
        thisInt = toSplit(k,:);
        cutInside = find(breakEPs(:,1)>=thisInt(1) & breakEPs(:,1)<=thisInt(2));
        orig(k,:) = [];

        for l = cutInside'
            newStates = [newStates;thisInt(1) breakEPs(l,1)];
            thisInt = [breakEPs(l,2) thisInt(2)];
        end
    end
    newStates = [newStates;thisInt];
    out = [orig;newStates];
    out = sortrows(out);
    out(diff(out,1,2)<minDur,:) = [];


