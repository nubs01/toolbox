function [swDat,thDat] = pickSWTHlfp(animID,dataDir,sessionNum,epochNum,varargin)
    % [swDat,thDat] = pickSWTHlfp(animID,dataDir,sessionNum,epochNum,varargin)
    % looks through all tetrodes available for the best tetrodes for theta
    % detection and slow wave detection. 
    % NAME-VALUE PAIRS
    % validTets : list of valid tetrodes to choose from
    % rejectTets: list of tetrodes to ignore/exclude from selection
    % saveFigs  : Boolean flag on whether or not to generate and save figures,
    %             saves to animID_analysis dir created in parent directory of dataDir 
    
    validTets = [];
    rejectTets = [];
    saveFigs = true;
    resampleFs = 250; % Hz to resample lfp output at for state scoring
    
    % Windowing and detection parameters
    winSize = 10;
    winStep = 1;
    nhistbins = 21;
    nfreqpts = 100;
    sw_freqRange = [0 2];
    th_freqRange = [5 10];
    all_freqRange = [2 20];
    swTransientThresh = 5; % # std from mean total power for throwing out sw transient windows
    swSmoothFactor = 10; % units of si_FFT
    thSmoothFactor = 10;

    Notch60Hz = false;
    NotchUnder3Hz = false;
    NotchHVS = false;
    NotchTheta  = false;

    assignVars(varargin)

    if isempty(validTets)
        % TODO: set to all tets in session & epoch from LFP files
    end
    validTets = setdiff(validTets,rejectTets);
    nTets = numel(validTets);

    eegDir = [dataDir filesep 'EEG' filesep];
    eegFile = @(x)sprintf('%s%seeg%02i-%02i-%02i.mat',eegDir,animID,sessionNum,epochNum,x);
    
    % Create parameter spaces
    histbins = linspace(0,1,nhistbins);
    swFFTfreqs = logspace(sw_freqRange(1),sw_freqRange(2),nfreqpts);
    thFFTfreqs = logspace(log10(all_freqRange(1)),log10(all_freqRange(2)),nfreqpts); % Note using log10 units for theta freqs

    %For SW calculation
    %Load the slowwave filter weights
    if ~exist('SWWeightsName','var')
        SWWeightsName = 'SWweights.mat';
    end
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

    % Initialize variables for computed metrics
    SWhists = zeros(nhistbins,nTets);
    dipSW = zeros(nTets,1);
    THhists = zeros(nhistbins,nTets);
    THmeanspec = zeros(nfreqpts,nTets);
    peakTH = zeros(nTets,1);
    swSpectra = cell(nTets,1);
    allBBSW = cell(nTets,1);
    thSpectra = cell(nTets,1);
    swSpecTime = cell(nTets,1);
    thSpecTime = cell(nTets,1);
    allThRatios = cell(nTets,1);

    % Go through all candidate tets in parallel and save metrics
    %parpool(nTets)
    parfor idx = 1:nTets
        tt = validTets(idx);
        fprintf('Calculating SW & TH metrics for tetrode %02i...\n',tt)
        eeg = load(eegFile(tt));
        eeg = eeg.eeg{sessionNum}{epochNum}{tt};
        Fs = eeg.samprate;

        [swSpec,~,t_FFT] = spectrogram(eeg.data,winSize*Fs,(winSize-winStep)*Fs,swFFTfreqs,Fs);
        swSpecTime{idx} = t_FFT;
        swSpec = abs(swSpec);
        [zswSpec,~,~] = zscore(log10(swSpec)');
        % remove transients
        totz = zscore(abs(sum(zswSpec')));
        badtimes = find(totz>swTransientThresh); % remove any time window whose total power is too far from mean
        zswSpec(badtimes,:) = 0;
        swSpectra{idx} = swSpec;

        broadbandSlowWave =  zswSpec*SWweights';
        broadbandSlowWave = smooth(broadbandSlowWave,swSmoothFactor);
        broadbandSlowWave = (broadbandSlowWave - min(broadbandSlowWave)); % Normalize
        broadbandSlowWave = broadbandSlowWave./max(broadbandSlowWave); % Normalize
        allBBSW{idx} = broadbandSlowWave;
        tmpHist = hist(broadbandSlowWave,histbins);
        SWhists(:,idx) = tmpHist;
        dipSW(idx) = hartigansdiptest_ss(sort(broadbandSlowWave));

        [thSpec,~,t_FFT] = spectrogram(eeg.data,winSize*Fs,(winSize-winStep)*Fs,thFFTfreqs,Fs);
        thSpecTime{idx} = t_FFT;
        thSpec = abs(thSpec);
        thSpectra{idx} = thSpec;
        thBand = thFFTfreqs>=th_freqRange(1) & thFFTfreqs<=th_freqRange(2);
        thPower = sum(thSpec(thBand,:),1);
        allPower = sum(thSpec,1);
        thratio = thPower./allPower;
        thratio = smooth(thratio,thSmoothFactor);
        thratio = (thratio - min(thratio))./max(thratio-min(thratio));
        allThRatios{idx} = thratio;
        THhists(:,idx) = hist(thratio,histbins);
        meanspec = mean(thSpec,2);
        meanthratio = sum(meanspec(thBand))./sum(meanspec(:));
        THmeanspec(:,idx) = meanspec;
        peakTH(idx) = meanthratio;
    end

    fprintf('Choosing Best Tetrodes...\n')
    [~,dipsortSW] = sort(dipSW);
    [~,dipsortTH] = sort(peakTH);
    bestSWidx = dipsortSW(end);
    bestTHidx = dipsortTH(end);
    bestSWtet = validTets(bestSWidx);
    bestTHtet = validTets(bestTHidx);
    fprintf('Best SW tetrode : %02i\nBest TH tetrode : %02i\n',bestSWtet,bestTHtet)

    % Make output structures
    sweeg = load(eegFile(bestSWtet));
    sweeg = sweeg.eeg{sessionNum}{epochNum}{bestSWtet};
    theeg = load(eegFile(bestTHtet));
    theeg = theeg.eeg{sessionNum}{epochNum}{bestTHtet};
    eegTime = sweeg.starttime:1/sweeg.samprate:sweeg.endtime;
    swSpec = swSpectra{bestSWidx};
    thSpec = thSpectra{bestTHidx};
    bbSW = allBBSW{bestSWidx};
    swHist = SWhists(:,bestSWidx);
    thHist = THhists(:,bestTHidx);
    thRatio = allThRatios{bestTHidx};
    thSpecTime = thSpecTime{1};
    swSpecTime = swSpecTime{1};

    % resample sw and th eeg data to 250Hz used in state clustering
    [sweeg,swTime] = resample(sweeg.data,eegTime,resampleFs);
    [theeg,thTime] = resample(theeg.data,eegTime,resampleFs);


    swDat = struct('tetrode',bestSWtet,'lfp_data',sweeg','lfp_time',swTime,'samprate',resampleFs,...
                    'spec_freqs',swFFTfreqs,'specgram',swSpec,'broadbandSlowWave',bbSW',...
                    'slowWave_hist',swHist,'histbins',histbins,'spec_time',swSpecTime);
    thDat = struct('tetrode',bestTHtet,'lfp_data',theeg','lfp_time',thTime,'samprate',resampleFs,...
                   'spec_freqs',thFFTfreqs,'specgram',thSpec,'thratio',thRatio','thratio_hist',thHist',...
                   'histbins',histbins,'spec_time',thSpecTime,'mean_spec',THmeanspec(:,bestTHidx)');
    % Make Plots

    if saveFigs
        fprintf('Plotting and Saving figures...\n')
        f1 = figure();
        subplot(2,1,1)
            imagesc(histbins,1:nTets,SWhists(:,dipsortSW)')
            axis xy
            ylabel('Channel #')
            xlabel('SW Band Projection Weight')
            title('SW Band Projection Histogram: All Channels')
        subplot(2,1,2)
            set(gca,'ColorOrder',hsv(nTets))
            hold all
            plot(histbins,SWhists')
            plot(histbins,swHist','k','LineWidth',2)
            ylabel('Counts')
            xlabel('SW Band Projection Weight')
            title('SW Band Projection Histogram: All Channels')

        f2 =  figure();
        subplot(2,2,1)
            imagesc(log2(thFFTfreqs),1:nTets,THmeanspec(:,dipsortTH)')
            axis xy
            ylabel('Channel #')
            xlabel('Frequency (Hz)')
            LogScale_ss('x',2)
            title('Spectrum: All Channels')
        subplot(2,2,2)
            imagesc(histbins,1:nTets,THhists(:,dipsortTH)')
            axis xy
            ylabel('Channel #')
            xlabel('Theta projection weight')
            title('Theta Ratio Histogram: All Channels')
        subplot(2,2,3)
            set(gca,'ColorOrder',RainbowColors_ss(length(dipsortTH)))
            hold all
            plot(log2(thFFTfreqs),THmeanspec')  
            plot(log2(thFFTfreqs),thSpec','k','LineWidth',2)
            plot(log2(th_freqRange(1))*[1 1],get(gca,'ylim'),'k')
            plot(log2(th_freqRange(2))*[1 1],get(gca,'ylim'),'k')
            ylabel('Power')
            xlabel('Frequency (Hz)')
            xlim(log2(all_freqRange))
            LogScale_ss('x',2)
            title('Spectrum: All Channels')
        subplot(2,2,4)
            set(gca,'ColorOrder',hsv(length(dipsortTH)))
            hold all
            plot(histbins,THhists')
            plot(histbins,thHist','k','LineWidth',2)
            ylabel('Counts')
            xlabel('Theta projection weight')
            title('Theta Ratio Histogram: All Channels')

        f3 = figure();
        subplot(5,1,1:2)
            [~,mu,sig] = zscore(log10(swSpec)');
            imagesc(swSpecTime,log2(swFFTfreqs),log10(swSpec))
            colormap(magma)
            axis xy
            LogScale_ss('y',2)
            caxis([min(mu)-2.5*max(sig) max(mu)+2.5*max(sig)])
            xlim(swSpecTime([1 end]))
            ylabel({'LFP-FFT','Frequency(Hz)'})
            title(sprintf('Slow Wave Channel: %02i',bestSWtet))

        subplot(5,1,3)
            [~,mu,sig] = zscore(log10(thSpec)');
            plot(swSpecTime,bbSW,'k','LineWidth',2)
            xlim(swSpecTime([1 end]))
            set(gca,'XTick',[])
            title('Broadband Slow Wave')

        subplot(5,1,4)
            imagesc(thSpecTime,log2(thFFTfreqs),log10(thSpec))
            colormap(magma)
            axis xy
            hold on
            plot(thSpecTime([1 end]),log2(th_freqRange([1 1])),'w')
            plot(thSpecTime([1 end]),log2(th_freqRange([2 2])),'w')
            LogScale_ss('y',2)
            caxis([min(mu)-2.5*max(sig) max(mu)+2.5*max(sig)])
            ylim(log2(thFFTfreqs([1 end]))+0.2)
            ylabel({'LFP - FFT','Frequency(Hz)'})
            title(sprintf('Theta Tetrode: %02i',bestTHtet))
            xlim(thSpecTime([1 end]))
            set(gca,'XTick',[])

        subplot(5,1,5)
            plot(thSpecTime,thRatio,'k')
            xlim(thSpecTime([1 end]))
            set(gca,'XTick',[])
            title('Theta Ratio')

        if dataDir(end)==filesep
            dataDir = dataDir(1:end-1);
        end
        figDir = [fileparts(dataDir) filesep animID '_analysis' filesep];
        saveFile = @(x) sprintf('%s%s_%s%02i-%02i',figDir,animID,x,sessionNum,epochNum);
        mkdir(figDir)
        saveas(f1,saveFile('pickSWTet'),'png')
        saveas(f2,saveFile('pickTHTet'),'png')
        saveas(f3,saveFile('bestSWTHTets'),'png')
    end
