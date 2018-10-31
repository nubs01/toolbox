function createStateValidationDatafile(animID,day,epoch,varargin)
    overwrite = 0;
    assignVars(varargin)
    disp(animID)

    saveFile = sprintf('%s/%s_direct/SleepStates/%sstateValDat%02i-%02i.mat',get_data_path('sz_data',animID),animID,animID,day,epoch);
    if exist(saveFile,'file') && ~overwrite
        fprintf('File Already Exists\n')
        return;
    end
    stateValDat = cell(1,day);
    stateValDat{day}{epoch} = getStateValidationData(animID,day,epoch);
    save(saveFile,'stateValDat')

