function mountainSortAnim(animID,varargin)
    % mountainSortAnim(animID)
    %

    projDir = '/home/roshan/Projects/';
    sessionNum = [];
    forceTets = [];
    mask_artifacts = 1;

    assignVars(varargin)

    animDat = getAnimMetadata(animID);
    if isempty(animDat)
        fprintf('Animal %s not found in metadata DB.\n',animID)
        return;
    end
    recDat = animDat.recording_data;
    days = [recDat.day];
    if ~isempty(sessionNum)
        [~,ia] = intersect(days,sessionNum);
        recDat = recDat(ia);
        days = days(ia);
        missing = setdiff(sessionNum,days);
        if isempty(missing)
            arrayfun(@(x) fprintf('Could not find recording metadata for day %02i\n',x),missing)
        end
    end
    if isempty(days)
        disp('No days to process')
        return;
    end


    for k=1:numel(days)
        dd = days(k);
        tet_info = recDat(k).tet_info;
        validTets = ([tet_info.riptet] | [tet_info.single_unit]) & ~[tet_info.exclude];
        allTets = [tet_info.tetrode];
        tet_list = allTets(validTets);
        if ~isempty(forceTets)
            tet_list=forceTets;
        end

        rawDir = [projDir animDat.project filesep animDat.experiment_dir filesep animID filesep];
        ml_process_animal(animID,rawDir,'sessionNums',dd,'tet_list',tet_list,'mask_artifacts',mask_artifacts);
    end

