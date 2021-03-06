function out = removeTransientStates(X,lim,varargin)
% out = removeTransientStates(X,lim) looks at a classified data vector and
% adjusts episodes <lim points to match either the preceding or following
% state. If two transients are next to each other, the short one will be
% adjusted. 

assignVars(varargin)
out = X;
contPts = contiguous(X);
nStates = size(contPts,1);
epMat = vertcat(contPts{:,2});
epMat = sortrows(epMat,1);
D = diff(epMat,1,2);
S = X(epMat(:,1));
prevEP = [S(1) D(1) epMat(1,:)];
twoBack = prevEP;
skipnext=0;

for k=2:size(epMat,1)
    if skipnext
        skipnext = 0;
        continue;
    end
    
    if D(k)>=lim
        if prevEP(1) == S(k)
            prevEP(2) = prevEP(2) + D(k);
            prevEP(4) = epMat(k,2);
        else
            if prevEP(2)<lim
                out(prevEP(3):prevEP(4)) = twoBack(1);
            end
            prevEP = [S(k) D(k) epMat(k,:)];
        end
        
        continue;
    end
    
    if prevEP(1)==S(k)
        prevEP(2) = prevEP(2)+D(k);
        prevEP(4) = epMat(k,2);
        continue;
    end
    
    if k==size(epMat,1)
        out(epMat(k,1):epMat(k,2)) = prevEP(1);
        continue;
    end
    
    nextEP = [S(k+1) D(k+1) epMat(k+1,:)];
    if nextEP(1) == prevEP(1) && prevEP(2)>D(k) &&  nextEP(2)>D(k)
        out(epMat(k,1):epMat(k,2)) = prevEP(1);
        prevEP(2) = prevEP(2)+D(k);
        prevEP(4) = epMat(k,2);
        continue;
    end
    if prevEP(2)<lim && nextEP(2)<lim && nextEP(1)==prevEP(1)
        out(epMat(k,1):epMat(k,2)) = prevEP(1);
        prevEP(2) = prevEP(2)+D(k);
        prevEP(4) = epMat(k,2);
        continue;
    end
    if prevEP(2)<lim
        out(prevEP(3):prevEP(4)) = twoBack(1);
        twoBack(2) = twoBack(2)+prevEP(2);
        twoBack(4) = prevEP(4);
    else
        twoBack = prevEP ;
    end
    prevEP = [S(k) D(k) epMat(k,:)];
end