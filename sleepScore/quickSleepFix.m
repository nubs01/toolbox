function quickSleepFix(animID,day,epoch)

    [stateStruct,stateFile] = get_ff_data(animID,'states',day,'subFolder','SleepStates');
    emg = get_ff_data(animID,'emgfromlfp',day,epoch,'subFolder','EMG');
    pos = get_ff_data(animID,'pos',day);
    pos = pos{epoch};
    tmpS = stateStruct{epoch};

    out = getSleepWakeStates(emg,pos,'fromLFP',true);

    tmpS.state_mat = out.state_mat;
    tmpS.state_names=out.state_names;
    tmpS.detector=['getSleepWakeStates.m (Miyawaki & Diba 2016);prev: ' tmpS.detector];
    tmpS.decetion_date=[datetime('now');tmpS.decetion_date];

    stateStruct{epoch} = tmpS;
    states = cell(1,day);
    states{day} = stateStruct;
    save(stateFile,'states');

