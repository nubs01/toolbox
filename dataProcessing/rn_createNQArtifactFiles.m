function rn_createNQArtifactFiles(dataDir,animID,sessionNum,varargin)
% Grabs LFP from all tetrodes for a given day and identifies artifacts by noting periods of high (> nstd from mean) cross-correlation. Data is saved in filterframework format.
% NAME-VALUE pairs
% nstd   : number of std deviations above mean cross-correlation to threshold at [default = 1]
% winSize: window size in seconds to break data into for analysis [default = 1]
% ignoreTets: list of tetrodes to ignore (default = [])
% manualVerify: flag of whether to open a manual artifact verifaction window before saving file [default=0]

fprintf('Detecting and Labelling artifacts for day %02i...\n',sessionNum)
nstd = 1; % number of std from mean cross-correlation to be classified as an artifact
winSize = 1; % window size in seconds for artifact labelling
manualVerify = 0; %flag for manual verification TODO: Make manual verification GUI
ignoreTets = [];

assignVars(varargin)

eegDir = [dataDir filesep 'EEG' filesep];
artDir = [dataDir filesep 'Artifacts' filesep];
if ~exist(artDir,'dir')
    mkdir(artDir)
end

% Get all EEG files for the day
eegFiles = dir(sprintf('%s%seeg%02i-*-*.mat',dataDir,animID,sessionNum));
if isempty(eegFiles)
    fprintf('No EEG files found for day %02i. Skipping...\n',sessionNum);
    return;
end
eegFiles = {eegFiles.name};
parsed = cellfun(@(x) parseDataFilename(x,animID),eegFiles);
epochs = unique(str2double({parsed.epoch}));
dataIndices = [str2double({parsed.day})' str2double({parsed.epoch})' str2double({parsed.tet})'];

% Detect Artifacts and create file for each epoch
for ee=epochs
    fprintf('    Processing %s day %02i epoch %02i...\n',animID,sessionNum,ee)
    saveFile = sprintf('%s%sartifacts%02i-%02i.mat',artDir,animID,sessionNum,ee);
    if exist(saveFile,'file')
        fprintf('Artifact file already exists for Day %02i Epoch %02i.  Skipping...\n',sessionNum,ee);
        continue;
    end
    tets = dataIndices(dataIndices(:,2)==ee,3);
    if ~isempty(ignoreTets)
        tets = setdiff(tets,ingnoreTets);
    end
    nTets = numel(tets);
    eegCell = cell(nTets,1);
    timeVec = [];
    Fs = [];


    for l=1:nTets
        tt = tets(l);
        eeg = load([eegDir eegFiles{dataIndices(:,2)==ee & dataIndices(:,3)==tt}]);
        eeg = eeg.eeg{sessionNum}{ee}{tt};
        eegCell{l} = eeg.data';
        if isempty(timeVec)
            Fs = eeg.samprate;
            timeVec = eeg.starttime:1/Fs:eeg.endtime;
        end
    end

    nDat = numel(timeVec);
    eegMat = vercat(eegCell{:,4}); % matrix of eeg traces from all tetrodes (rows) in the epoch

    % Truncate so windows tile whole dataset
    winPts = winSize*Fs;
    newEnd = nDat-mod(nDat,winPts);
    newT = timeVec(1:newEnd);
    eegMat = eegMat(:,1:newEnd);
    nWin = newEnd/nWin;
    xcorrVec = zeros(1,nWin);
    for l=1:nWin
        winEEG = eegMat(:,(l-1)*winPts+1:l*winPts);
        tetPairs = nchoosek(1:size(eegMat,1),2);
        tmpCorr = zeros(size(tetPairs,1),1);
        for m=1:size(tetPairs,1)
            [cr,lgs] = xcorr(winEEG(tetPairs(m,1),:),winEEG(tetPairs(m,2),:));
            tmpCorr(m) = cr(lgs==0);
        end
        xcorrVec(l) = mean(tmpCorr);
    end
    thresh = mean(xcorrVec) + nstd*std(xcorrVec);
    winTime = newT(1)+winSize/2:winSize:newT(end);
    tmpArts = xcorrVec>thresh;
    tmp = contiguous(tmpArts,1);
    slowArts  = tmp{2};
    slowArtTimes = winTime(slowArts);
    slowArtTimes = slowArtTimes + [-winSize/2 winSize/2];
    slowArtTimes(slowArtTimes<newT(1)) = newT(1);
    slowArtTimes(slowArtTimes>newT(end)) = newT(end);
    
    if manualVerify
        slowArtEEGIdx = zeros(size(slowArtTimes));
        for l=1:size(slowArtTimes,1)
            slowArtEEGIdx(l,1) = find(newT>=slowArtTimes(l,1),1,'first');
            slowArtEEGIdx(l,2) = find(newT<=slowArtTimes(l,2),1,'last');
        end
        % TODO: Add gui to display eeg traces and move through artifacts and reject if needed
    end

    % Save artifact file
    outStruct = struct('artifact_vector',tmpArts,'xcorr_vector',xcorrVec,'time_vector',winTime,'window_size',winSize,'thresh_std',nstd,'thresh',thresh,'artifact_times',slowArtTimes,'tetrodes_used',tets);
    artifacts = cell(1,sessionNum);
    artifacts{sessionNum} = cell(1,ee);
    artifacts{sessionNum}{ee} = outStruct;
    save(saveFile,'artifacts')

    clear artifacts slowArtTimes
end


% Store:
%   - data vector with artifacts as 1's 
%   - matrix with artifact epoch start and end times
%   - time vector
%   - tetrodes used in artifact detection
%   - cross-correlation vector
%   - thresh_std: nstd

