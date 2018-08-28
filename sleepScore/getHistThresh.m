function [outHist,histbins,PkLocs,Thresh] = getHistThresh(datVec,varargin)
    numbins = 12;
    nPks = 1;
    maxBins = inf;
    assignVars(varargin)

    while nPks ~=2 && nPks<=maxBins
        [outHist,histbins] = hist(datVec,numbins);
        [~,PkLocs] = findpeaks_SleepScore(outHist,'NPeaks',2,'SortStr','descend');
        PkLocs = sort(PkLocs,'ascend');
        numbins = numbins+1;
        nPks = numel(PkLocs);
    end

    if nPks==2
        tmp = outHist(PkLocs(1):PkLocs(2));
        tmpbins = histbins(PkLocs(1):PkLocs(2));
        [~,diploc] = findpeaks_SleepScore(-tmp,'NPeaks',1,'SortStr','descend');
        Thresh = tmpbins(diploc);
    else
        Thresh = 0;
    end
