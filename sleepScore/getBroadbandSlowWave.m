function [broadbandSlowWave,t_FFT,badtimes] = getBroadbandSlowWave(lfp,Fs,varargin)

    winSize = 10; % seconds
    winStep = 1; % seconds
    swTransientThresh = 5;
    swSmoothFactor = 10;
    nFreqPts = 100;
    SWWeightsName = 'SWweights.mat';
    Notch60Hz = 0;
    NotchUnder3Hz = 0;
    NotchHVS = 0;
    NotchTheta = 0;

    assignVars(varargin)
    
    swFFTfreqs = logspace(0,2,nFreqPts);
    %For SW calculation
    tmp = load(SWWeightsName); % 'SWweights.mat' by default
    SWweights =  tmp.SWweights;
    SWfreqlist = tmp.SWfreqlist;
    %Alter the filter weights if requested by the user
    if Notch60Hz; SWweights(SWfreqlist<=62.5 & SWfreqlist>=57.5) = 0; end
    if NotchUnder3Hz; SWweights(SWfreqlist<=3) = 0; end
    if NotchHVS
        SWweights(SWfreqlist<=18 & SWfreqlist>=12) = 0;
        SWweights(SWfreqlist<=10 & SWfreqlist>=4) = 0;
    end
    if NotchTheta; SWweights(SWfreqlist<=10 & SWfreqlist>=4) = 0; end
    assert(isequal(swFFTfreqs,SWfreqlist), 'spectrogram freqs.  are not what they should be...')

    [swSpec,~,t_FFT] = spectrogram(lfp,winSize*Fs,(winSize-winStep)*Fs,swFFTfreqs,Fs);
    swFs = winStep;
    swSpec = abs(swSpec);
    [zswSpec,~,~] = zscore(log10(swSpec)');
    % remove transients
    totz = zscore(abs(sum(zswSpec')));
    badtimes = find(totz>swTransientThresh); % remove any time window whose total power is too far from mean
    zswSpec(badtimes,:) = 0;

    broadbandSlowWave =  zswSpec*SWweights';
    broadbandSlowWave = smooth(broadbandSlowWave,swSmoothFactor*swFs);
    broadbandSlowWave = (broadbandSlowWave - min(broadbandSlowWave)); % Normalize
    broadbandSlowWave = broadbandSlowWave./max(broadbandSlowWave); % Normalize
