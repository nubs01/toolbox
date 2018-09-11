function out = getSleepWakeStates(emg,pos,varargin)
    % out = getSleepWakeStates(emg,pos)
    % Classifies sleep periods based on Miyawaki & Diba 2016
    % NAME-VALUE pairs
    % emgHighThresh   : std
    % emgLowThresh    : std
    % velHighThresh   : cm/s
    % velLowThresh    : cm/s
    % ignoreTransients: second, length of transient EMG states to ignore

    emgHighThresh = 0.5;
    emgLowThresh = 0;
    velHighThresh = 5;
    velLowThresh = 0.5;
    ignoreTransients = 10; 
    emgFs = 10;
    minSleepDur = 40; % seconds, onnly used if EMG is unavailable

    assignVars(varargin)

    velCol = strcmpi(strsplit(pos.fields,' '),'vel');
    timeCol = strcmpi(strsplit(pos.fields,' '),'time');
    [vel,velTime]  = cleanVelocity(pos.data(:,velCol),pos.data(:,timeCol),'newFs',25);

    % if emg is empty (does not exist) classify sleep as "no movement"  for >=40s
    if isempty(emg)
        velClasses = twoThreshSchmittTrigger(vel,velHighThresh,velLowThresh);
        nomove = velClasses==-1;
        tmpS = contiguous(nomove,1);
        tmpSM = velTime(tmpS{2});
        SD = diff(tmpSM,1,2);
        notsleep = SD<minSleepDur;
        tmpSM(notsleep,:)  = [];
        stateTime = velTime(1):1/emgFs:velTime(end);
        stateVec = zeros(size(stateTime));
        for k=1:size(tmpSM,1)
            a = stateTime>=tmpSM(k,1) & stateTime<=tmpSM(k,2);
            stateVec(a) = 1;
        end
        stateVec(stateVec==0) = 2;
    else
        if isfield(emg,'time')
            emgTime = emg.time;
        else
            emgTime = emg.starttime:1/emg.samprate:emg.endtime;
        end
        [zEMG,emgTime2] =  processRawEMG(emg.data,emgTime,emg.samprate,'step',1/emgFs);

        emgClasses = twoThreshSchmittTrigger(zEMG,emgHighThresh,emgLowThresh);
        emgClasses2 = removeTransientStates(emgClasses,ignoreTransients*emgFs);

        velClasses = twoThreshSchmittTrigger(vel,velHighThresh,velLowThresh);
        velClasses2 = interp1(velTime,velClasses,emgTime2,'previous');
        sleep = (emgClasses2==-1) & (velClasses2==-1);
        wake = ~sleep;
        stateTime = emgTime2;
        stateVec = sleep+2*wake;
    end
    tmpS = contiguous(stateVec,1);
    tmpSM = [tmpS{2} repmat(1,size(tmpS{2},1),1)];
    tmpW = contiguous(stateVec,2);
    tmpWM = [tmpW{2} repmat(2,size(tmpW{2},1),1)];
    tmp = [tmpSM;tmpWM];
    tmp = sortrows(tmp,1);
    tmpTimes = tmp;
    tmpTimes(:,1:2) = stateTime(tmp(:,1:2));
    out = struct('time_vec',stateTime,'state_vec',stateVec,'state_mat',tmpTimes);
