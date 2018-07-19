function [newEMG,newTime] = processRawEMG(rawEMG,emgTime,fs,varargin)
% [newEMG,newTime] = processRawEMG(rawEMG,emgTime,fs)
% processes EMG as per Miywaki & Diba 2016 to be used to sleep
% classification

binSize = .5; % seconds
step = .1; % seconds
smoothWin = 1; % seconds for gaussian filter width

assignVars(varargin)

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


