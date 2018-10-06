function out = parseDataFilename(fn,animID)
    % Given a data filename fn (s.a. 'RW6eeg01-03-02.mat') and an animal ID
    % ('RW6') this will return a structure containing the data type (eeg) and
    % day, epoch and tetrode in a struct with fields type, day, epoch, tetrode

    if contains(fn,filesep)
        fn = fn(find(fn==filesep,1,'last'):end);
    end
    if ~exist('animID','var')
        pat = '(?<anim>[A-Z]+[0-9]+)';
        a = regexp(fn,pat,'names');
        animID = a.anim;
    end
        
    pat = [animID '(?<type>\D*)(?<day>\d+)-(?<epoch>\d+)-(?<tet>\d+).mat'];
    parsed = regexp(fn,pat,'names');
    if ~isempty(parsed)
        out = parsed;
        return;
    end
    pat = [animID '(?<type>\D*)(?<day>\d+)-(?<epoch>\d+).mat'];
    parsed = regexp(fn,pat,'names');
    if ~isempty(parsed)
        out = parsed;
        return;
    end
    pat = [animID '(?<type>\D*)(?<day>\d+).mat'];
    out = regexp(fn,pat,'names');
    
