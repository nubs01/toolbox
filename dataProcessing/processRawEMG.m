function [newEMG,newTime] = processRawEMG(rawEMG,emgTime,fs,varargin)
% [newEMG,newTime] = processRawEMG(rawEMG,emgTime,fs)
% processes EMG as per Miywaki & Diba 2016 to be used to sleep
% classification
% Smooth EMG with gaussian window, bin and zscore
% NAME-VALUE Pairs
% binSize : seconds (default .5s)
% step    : seconds (default 0.1s)
% smoothWin: seconds (default 1s)
% fromLFP : flag to designate  if EMG from derived from LFP with 
% rn_EMGFromLFP, changes parameters to 2s bin with 1s step and 2s smoothing
% window (these can all still be overwritten)

binSize = .5; % seconds
step = .1; % seconds
smoothWin = 1; % seconds for gaussian filter width
fromLFP = false;

assignVars(varargin)

if fromLFP
    binSize = 2;
    step = 1;
    smoothWin = 2;
    assignVars(varargin)
end

gWin = gausswin(smoothWin*fs);
gWin = gWin./sum(gWin);
fEMG = conv(rawEMG,gWin,'same');
pEMG = envelope(fEMG);

meanEMG = mean(pEMG);
stdEMG = std(pEMG);

[binEMG,binIdx] = slidingWindow(pEMG,fix(binSize*fs),fix(step*fs));
binTimes = emgTime(binIdx);
newTime = mean(binTimes);
newEMG = mean(binEMG);
newEMG  = (newEMG - meanEMG)./stdEMG;


