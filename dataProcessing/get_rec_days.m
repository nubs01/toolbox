function days = get_rec_days(animID)

    animDat = getAnimMetadata(animID);
    recDat = animDat.recording_data;
    if isempty(recDat)
        days = [];
    else
        days = [recDat.day];
    end
