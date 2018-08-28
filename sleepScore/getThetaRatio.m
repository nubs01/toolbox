function [thratio,t_FFT,meanspec,allFreqs,meanthratio] = getThetaRatio(lfpDat,Fs,varargin)
    % Returns a vector of theta power over all power normalized from 0 to 1 as
    % used for Buzsaki sleep scoring 
    % Default theta range is 5-10Hz and all range is 2-20Hz

    thetaRange = [5 10];
    allRange = [2 20];
    nFreqPts = 100;
    winSize = 10;
    winStep = 1;
    thSmoothFactor = 10;

    assignVars(varargin)

    allFreqs = logspace(log10(allRange(1)),log10(allRange(2)),nFreqPts);
    
    [thSpec,~,t_FFT] = spectrogram(lfpDat,winSize*Fs,(winSize-winStep)*Fs,allFreqs,Fs);
    thSpec = abs(thSpec);
    thBand = allFreqs>=thetaRange(1) & allFreqs<=thetaRange(2);
    thPower = sum(thSpec(thBand,:),1);
    allPower = sum(thSpec,1);
    thratio = thPower./allPower;
    thratio = smooth(thratio,thSmoothFactor*winStep);
    thratio = (thratio - min(thratio))./max(thratio-min(thratio));
    meanspec = mean(thSpec,2);
    meanthratio = sum(meanspec(thBand))./sum(meanspec(:));
