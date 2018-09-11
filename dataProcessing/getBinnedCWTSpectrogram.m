function [specgram,f,t] = getBinnedCWTSpectrogram(X,fs,winSize,varargin)


freqRange = [0 30];
freqRes = 0.25;

assignVars(varargin)

windowIdx = [(1:winSize/2:numel(X)-winSize)' (winSize:winSize/2:numel(X))'];

f = freqRange(1):freqRes:freqRange(2);
winTimes = windowIdx./fs;
t = mean(winTimes,2);
specgram = zeros(numel(f),numel(t));
for k=1:size(windowIdx,1)
    xx = X(windowIdx(k,1):windowIdx(k,2));
    [psd,f] = getPSD(xx,fs,'psdType','cwt','freqRange',freqRange,'freqRes',freqRes);
    specgram(:,k) = psd;
end

% remove frequencies with negative valued power
%[~,maxRmv] = max(sum(specgram<0));
%fRmvIdx = specgram(:,maxRmv)<0;
%f = f(~fRmvIdx);
%specgram = specgram(~fRmvIdx,:);
