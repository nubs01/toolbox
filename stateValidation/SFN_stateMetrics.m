% Metrics to get for each animal for each state
% number of episodes, avg episode duration & sd, total time in state (get per rec and avg for each animal,genotype,gender or geno_gender) - Sample equally from all animals in group
% first get min epoch length across animals/days for epoch_type and truncate all rec to min (rounded down to minute)
animals = {'RW7','RW8','RW9','RW10','RZ7','RZ8','RZ9','RZ10'};
ketAnim = {'RW9','RW10','RZ9','RZ10'};
epoch_types = {'Sleep','Saline','Ketamine'};
epoch = 'Sleep';

state_mats = cell(1,numel(animals));
min_ep_lengths = zeros(1,numel(animals));
indexes = [];
for k=1:numel(animals)
    anim = animals{k};
    animDat = getAnimMetadata(anim);
    recDat = animDat.recording_data;
    days = get_rec_days(anim);
    idx = [];
    for l=1:numel(recDat)
        for m=1:numel(recDat(l).epochs)
            if strcmpi(recDat(l).epochs(m).epoch_type,epoch)
                idx = [idx;l m];
            end
        end
    end
    state_mats{k} = cell(1,size(idx,1));
    tmp_lengths = zeros(1,size(idx,1));
    for l=1:size(idx,1)
        states = get_ff_data(anim,'states',idx(l,1),'subFolder','SleepStates');
        state_mats{k}{l} = states{idx(l,2)}.state_mat;
        tmp_lengths(l) = state_mats{k}{l}(end,2)-state_mats{k}{l}(1,1);
    end
    min_ep_lengths(k) = min(tmp_lengths);
    indexes = [indexes; repmat(k,size(idx,1),1) idx];
end

trunLen = floor(min(min_ep_lengths)/60)*60;


