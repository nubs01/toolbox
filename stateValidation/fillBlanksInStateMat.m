function out = fillBlanksInStateMat(stateMat,starttime,endtime,fillState)

[SM,idx] = sortrows(stateMat,1,'ascend');
[~,idx2] = sortrows(stateMat,2,'ascend');
if ~all(idx==idx2)
    error('stateMat must have no overlapping states')
end
if SM(1,1) <= starttime
    SM(1,1) = starttime;
end
if SM(1,1) > starttime
    SM = [starttime SM(1,1) fillState;SM];
end
if SM(end,2) >= endtime
    SM(end,2) = endtime;
end
if SM(end,2) < endtime
    SM = [SM;SM(end,2) endtime fillState];
end


for k=size(SM,1):-1:2
    if SM(k-1,2) < SM(k,1)
        SM = [SM(1:k-1,:);SM(k-1,2) SM(k,1) fillState;SM(k:end,:)];
    end
end

out = SM;