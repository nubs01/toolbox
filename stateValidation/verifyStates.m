function [stateDat,stateFile] = verifyStates(animID,sessionNum)

    contFlag = 1;
    changed = 0;
    [stateDat,stateFile] = get_ff_data(animID,'states',sessionNum,'subFolder','SleepStates');
    epochs = (1:numel(stateDat))';
    while contFlag
        verified = (cellfun(@(x) x.manually_verified,stateDat))';
        disp(table(epochs,verified,'VariableNames',{'Epoch','Verified'}))
        ee = input('Which epoch would you like to manually score (0 to cancel)?  ');
        if ee==0
            return;
        end

        valDat = getStateValidationData(animID,sessionNum,ee);
        try
            newStates = stateValidationGUI(valDat);
        catch ME
            newStates = [];
            rethrow(ME)
        end
        if ~isempty(newStates)
            stateDat{ee}.state_names = valDat.state_names;
            stateDat{ee}.state_mat = newStates;
            stateDat{ee}.manually_verified=1;
            changed = 1;
        else
            fprintf('Manual scoring aborted, no data changed\n')
        end
        qFlag = 1;
        while qFlag
            q = input('Would you like to sort another epoch (y/n)?  ','s');
            if strcmpi(q,'n')
                contFlag = 0;
                qFlag = 0;
            elseif strcmpi(q,'y')
                contFlag = 1;
                qFlag = 0;
            else
                qFlag = 1;
            end
        end
    end
    if changed
        states = cell(1,sessionNum);
        states{sessionNum} = stateDat;
        fprintf('Saving new state data to:\n\t%s\n',stateFile)
        save(stateFile,'states')
    else
        fprintf('No changes made to states file\n')
    end

            


