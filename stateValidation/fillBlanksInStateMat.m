function out = fillBlanksInStateMat(stateMat,starttime,endtime,fillState)

[SM,idx] = sortrows(stateMat,1,'ascend');
[~,idx2] = sortrows(stateMat,2,'ascend');
%disp('State Mat has overlapping states...fixing...')
SM = fixStateMat(SM);
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

function SM = fixStateMat(SM)
    out = SM;
    for k=1:size(SM,1)-1
        if SM(k,2)>SM(k+1,1)
            SM(k,2)=SM(k+1,1);
        end
    end
    %% if episode starts inside one episode and ends in another, truncate just to fill gap or delete
    %overlap = find(SM(1:end-1,2)>SM(2:end,1))';
    %%keyboard;
    %for k=overlap
    %    % if contained inside, split episode around
    %    if SM(k,2)>SM(k+1,2)
    %        tmp = SM(k,2);
    %        out(k,2) = SM(k+1,1);
    %        out = [out;SM(k+1,2) tmp SM(k,3)];
    %    elseif SM(k,2)<SM(k+1,2)
    %        if k+2<=size(SM,1) && SM(k+1,2)>SM(k+2,1)
    %            out(k+1,2) = SM(k+2,1);
    %        end
    %        out(k+1,1) = out(k,2);
    %    end
    %end
    %out = sortrows(out,1,'ascend');

    %% if episode is contained entirely inside another, break other around episode

