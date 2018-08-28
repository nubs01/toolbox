function episodes = IDStateEpisodes(ints,maxIntDur,minStateDur)

    % Merge States with valid interruptions
    [~,sort_idx] = sort(ints(:,2));
    ints = ints(sort_idx,:); % Sort by ending values
    gaps = ints(2:end,1) - ints(1:end-1,2);
    validGaps = find(gaps<=maxIntDur);
    ints(validGaps,2) = ints(validGaps+1,2);
    ints(validGaps,1) = min(ints(validGaps,1),ints(validGaps+1,1));
    ints(validGaps+1,:) = [];

    % only keep states longer than minStateDur
    validInts = diff(ints,1,2)>=minStateDur;
    episodes = ints(validInts,:);
