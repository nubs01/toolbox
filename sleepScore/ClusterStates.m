function sleepStates = ClusterStates(scoreData,varargin)

    v2struct(scoreData)
    % Min Window Parameters
    minSWsecs = 6;
    minWAKEsecs = 6;
    minREMsecs = 6;
    minREMinWsecs = 6;
    minWinREMsecs = 6;
    minWnexttoREMsecs = 6;
    minWinParams = v2struct(minSWsecs,minWAKEsecs,minREMsecs,...
                            minREMinWsecs,minWinREMsecs,minWnexttoREMsecs);
    emgSmoothFactor = 10;

    assignVars(varargin)

    if swDat.samprate~=250
        error('Downsample SW LFP to 250Hz')
        % TODO: Downsample here
    end
    if thDat.samprate~=250
        error('Downsample TH LFP to 250Hz')
        % TODO: Downsample here
    end
    
    [bbSW,t_fft,badtimes] = getBroadbandSlowWave(swDat.lfp_data,swDat.samprate);
    specFs = unique(diff(t_fft));
    if numel(specFs)>1
        error('Non-uniform spectrogram times')
    end

    thratio = getThetaRatio(thDat.lfp_data,thDat.samprate);
    
    EMGdat = emg.data;
    EMGtime = emg.time;
    EMGfs = emg.samprate;
    recTimeRange = emg.timerange;
    sEMG = smooth(EMGdat,EMGfs*emgSmoothFactor);
    nEMG = (sEMG-min(sEMG))./max(sEMG-min(sEMG));
    newEMG = interp1(EMGtime,nEMG,t_fft+recTimeRange(1),'linear','extrap')';

    [swHist,swHistBins,swPkLocs,swThresh] = getHistThresh(bbSW);
    bbSW(badtimes) = swHist(swPkLocs(1)); % Set broadbandSlowWave transients to wake
    NREMtimes = bbSW>swThresh;

    [emgHist,emgHistBins,emgPkLocs,emgThresh] = getHistThresh(newEMG(NREMtimes==0));
    MOVtimes = (bbSW<=swThresh & newEMG>=emgThresh);
    
    [thHist,thHistBins,thPkLocs,thThresh] = getHistThresh(thratio(~NREMtimes & ~MOVtimes),'maxBins',25);
    if thThresh==0
        REMtimes = (bbSW<=swThresh & newEMG<emgThresh);
    else
        REMtimes = (bbSW<=swThresh & newEMG<emgThresh & thratio>thThresh);
    end

    histandthreshs = v2struct(swHist,swHistBins,swPkLocs,swThresh,...
                              emgHist,emgHistBins,emgPkLocs,emgThresh,...
                              thHist,thHistBins,thPkLocs,thThresh);

    % make single state vector: WAKE=1, NREM=2 and REM=3
    IDX = MOVtimes + 2*NREMtimes + 3*REMtimes;

    % Change short NREM to WAKE
    IDX = convertShortStates(IDX,2,1,minSWsecs*specFs);
    
    % Change short WAKE next to REM into REM
    INT = IDXtoINT(IDX,3);


    Wint = INT{1};
    Wlens = diff(Wint,1,2);
    trans = diff(IDX);
    RWtrans = find(trans==-2)+1;
    WRtrans = find(trans==2);
    [~,RWtransON] = intersect(Wint(:,1),RWtrans);
    [~,WRtransOFF] = intersect(Wint(:,2),WRtrans);
    allTrans = union(RWtransON,WRtransOFF);
    shortIdx = Wlens(allTrans)<=minWnexttoREMsecs*specFs;
    shortIdx = allTrans(shortIdx);
    INT{3} = [INT{3};Wint(shortIdx,:)];
    INT{1}(shortIdx,:) = [];
    IDX = INTtoIDX(INT,numel(IDX));

    % Change short WAKE between REM into REM
    INT = IDXtoINT(IDX,3);
    Wint = INT{1};
    Wlens = diff(Wint,1,2);
    trans = diff(IDX);
    RWtrans = find(trans==-2)+1;
    WRtrans = find(trans==2);
    [~,RWtransON] = intersect(Wint(:,1),RWtrans);
    [~,WRtransOFF] = intersect(Wint(:,2),WRtrans);
    allTrans = intersect(RWtransON,WRtransOFF);
    shortIdx = Wlens(allTrans)<=minWinREMsecs*specFs;
    shortIdx = allTrans(shortIdx);
    INT{3} = [INT{3};Wint(shortIdx,:)];
    INT{1}(shortIdx,:) = [];
    IDX = INTtoIDX(INT,numel(IDX));

    % Change short REM between WAKE into WAKE
    INT = IDXtoINT(IDX,3);
    Rints = INT{3};
    Rlens = diff(Rints,1,2);
    trans = diff(IDX);
    RWtrans = find(trans==-2);
    WRtrans = find(trans==2)+1;
    [~,RWtransON] = intersect(Rints(:,2),RWtrans);
    [~,WRtransOFF] = intersect(Rints(:,1),WRtrans);
    allTrans = intersect(RWtransON,WRtransOFF);
    shortIdx = Rlens(allTrans)<=minREMinWsecs*specFs;
    shortIdx = allTrans(shortIdx);
    INT{1} = [INT{1};Rints(shortIdx,:)];
    INT{3}(shortIdx,:) = [];
    IDX = INTtoIDX(INT,numel(IDX));

    % Change all short REM into WAKE
    IDX = convertShortStates(IDX,3,1,minREMsecs*specFs);

    % Change short WAKE into NREM
    IDX = convertShortStates(IDX,1,2,minWAKEsecs*specFs);

    % Change short NREM into WAKE (yes, again!)
    IDX = convertShortStates(IDX,2,1,minSWsecs*specFs);
    INT = IDXtoINT(IDX,3);

    % make time vector for IDX, convert INT to time in seconds
    idxTime = t_fft + recTimeRange(1);
    sleepStates.time_range = recTimeRange;
    sleepStates.WAKEints = idxTime(INT{1});
    sleepStates.NREMints = idxTime(INT{2});
    sleepStates.REMints = idxTime(INT{3});
    sleepStates.histandthreshs = histandthreshs;
    sleepStates.minWinParams = minWinParams;
    sleepStates.detector = 'ClusterStates.m (Buzsaki)';
    sleepStates.swTet = swDat.tetrode;
    sleepStates.thTet = thDat.tetrode;



    
function [IDX] = convertShortStates(IDX,fromState,toState,minDur)
    INT = IDXtoINT(IDX,3);
    intLens = diff(INT{fromState},1,2);
    shortLens = intLens<=minDur;
    INT{toState} = [INT{toState}; INT{fromState}(shortLens,:)];
    INT{fromState}(shortLens,:) = [];
    IDX = INTtoIDX(INT,numel(IDX));
    

function IDX = INTtoIDX(INT,nPts)
    IDX = zeros(1,nPts);
    for k=1:numel(INT)
        ints = INT{k};
        for j=1:size(ints,1)
            a = ints(j,1):ints(j,2);
            IDX(a) = k;
        end
    end
