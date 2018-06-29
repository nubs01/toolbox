function rn_createNQArtifactFiles(dataDir,animID,sessionNum,varargin)
% Grabs LFP from all tetrodes for a given day and identifies artifacts by noting periods of high (> nstd from mean) cross-correlation. Data is saved in filterframework format.
% NAME-VALUE pairs
% nstd   : number of std deviations above mean cross-correlation to threshold at [default = 1]
% winSize: window size in seconds to break data into for analysis [default = 1]
% manualVerify: flag of whether to open a manual artifact verifaction window before saving file [default=0]

fprintf('Detecting and Labelling artifacts for day %02i...\n',sessionNum)
nstd = 1; % number of std from mean cross-correlation to be classified as an artifact
winSize = 1; % window size in seconds for artifact labelling
manualVerify = 0; %flag for manual verification TODO: Make manual verification GUI

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


% Store:
%   - data vector with artifacts as 1's 
%   - matrix with artifact epoch start and end times
%   - time vector
%   - tetrodes used in artifact detection
%   - cross-correlation vector
%   - thresh_std: nstd

