function [dataMatrix,dataHeaders] = createDataMatrix(animID,varargin)
    % out = createDataMatrix(animIDs,varargin)
    % creates a matrix in tiddy data format  containing the power spectrum for
    % each winSize second window of data

    winSize = 1; % seconds
    winStep = 1; % seconds
    all_band = [0 100];
    delta_band = [1 5];
    theta_band = [6 10];
    dataDir = [get_data_path('sz_data',animID) filesep animID '_direct' filesep];
    outFile = [dataDir animID 'dataMatrix.csv'];

    assignVars(varargin)

    animDat = getAnimMetadata(animID);
    recDays = [animDat.recording_data.day];
    dataHeaders = {'animID','genotype','gender','estrus','age','weight_change','rec_time','day','epoch','tetrode',...
                    'epoch_type','window_time','win_start','win_end','sleep_state',...
                    'mean_velocity','EMG_power','total_power','mean_power',...
                    'median_power','std_power','total_delta','mean_delta',...
                    'median_delta','std_delta','total_theta','mean_theta',...
                    'median_theta','std_theta'};
    dataMatrix = cell(1,numel(dataHeaders));
    genotype = animDat.genotype;
    gender = animDat.gender;

    fprintf('Processing %s\n------\nLooping days...\n',animID)
    for k=1:numel(recDays)
        dd = recDays(k);
        recDat = animDat.recording_data(k);
        tetInfo = recDat.tet_info;
        epoDat = recDat.epochs;
        epochNums = [epoDat.epoch];

        age = recDat.age;
        estrus = recDat.estrus;
        weight_change = str2double(animDat.preimplant_weight)-recDat.weight;
        rec_time = datestr(recDat.time,'HH:MM:SS');
        pos = get_ff_data(animID,'pos',dd);
        states = get_ff_data(animID,'states',dd,'subFolder','SleepStates');

        % Find relevant tetrodes (CA1 riptets that are not excluded)
        validTets = [tetInfo.riptet] & ~[tetInfo.exclude] & strcmpi({tetInfo.target},'CA1');
        tetNums = [tetInfo.tetrode];
        tetNums = tetNums(validTets);
        fprintf('Rip tets found:\n')
        disp(tetNums)

        fprintf('Looping epochs...\n')
        for l=1:numel(epochNums)
            ee = epochNums(l);
            epoch_type = epoDat(l).epoch_type;
            posFields = strsplit(pos{ee}.fields,' ');
            velCol = strcmpi(posFields,'vel');
            timeCol = strcmpi(posFields,'time');
            emg = get_ff_data(animID,'emgfromlfp',dd,ee,'subFolder','EMG');
            emgTime = emg.time;
            time_range = emg.timerange;
            [velocity,velTime] = cleanVelocity(pos{ee}.data(:,velCol),pos{ee}.data(:,timeCol));

            time_windows = [(time_range(1):winStep:time_range(2)-winSize)' (time_range(1)+winSize:winStep:time_range(2))'];
            fprintf('%i windows detected\nCreating mean velocity vector...\n',size(time_windows,1))
            vel_vec = arrayfun(@(x,y) mean(velocity(velTime>=x & velTime<=y)),time_windows(:,1),time_windows(:,2));
            fprintf('Creating mean EMG vector...\n')
            emg_vec = arrayfun(@(x,y) mean(emg.data(emgTime>=x & emgTime<=y)),time_windows(:,1),time_windows(:,2));

            state_mat = states{ee}.state_mat;
            state_names = states{ee}.state_names;
            if any(strcmpi(state_names,'transition'))
                transition = find(strcmpi(state_names,'transition'));
            else
                state_names{end+1} = 'transition';
                transition = numel(state_names);
            end
            fprintf('Creating sleep state vector...\n')
            state_vec = get_state_vector(state_mat,time_windows,transition);


            fprintf('Looping tetrodes and getting spectral metrics...\n')
            for m=1:numel(tetNums)
                tt = tetNums(m);
                cwtspec = get_ff_data(animID,'cwtspecgram',dd,ee,tt,'subFolder','Spectrograms');
                freq_vec = cwtspec.frequency;
                win_centers = cwtspec.window_centers;
                all_idx = freq_vec>=all_band(1) & freq_vec<=all_band(2);
                delta_idx = freq_vec>=delta_band(1) & freq_vec<=delta_band(2);
                theta_idx = freq_vec>=theta_band(1) & freq_vec<=theta_band(2);
                
                for n=1:size(time_windows,1)
                    t1 = time_windows(n,1);
                    t2 = time_windows(n,2);

                    idx = win_centers>=t1 & win_centers<=t2;
                    spec = mean(abs(cwtspec.spectrogram(:,idx)),2);
                    power_vec = {sum(spec(all_idx)),mean(spec(all_idx)),median(spec(all_idx)),std(spec(all_idx)),...
                                sum(spec(delta_idx)),mean(spec(delta_idx)),median(spec(delta_idx)),std(spec(delta_idx)),...
                                sum(spec(theta_idx)),mean(spec(theta_idx)),median(spec(theta_idx)),std(spec(theta_idx))};


                    % add data row
                    dataMatrix(end+1,:) = [animID,genotype,gender,estrus,age,weight_change,...
                                            rec_time,dd,ee,tt,epoch_type,mean(time_windows(n,:)),...
                                            time_windows(n,1),time_windows(n,2),state_names{state_vec(n)},...
                                            vel_vec(n),emg_vec(n),power_vec];
                end
            end
        end
    end
    dataMatrix = dataMatrix(2:end,:);
    if ~isempty(outFile)
        writeCell2PandasCSV(outFile,dataMatrix,'headers',dataHeaders)
    end

function out = get_state_vector(sm,tw,transition)
    out = zeros(size(tw,1),1);
    for k=1:size(tw,1)
        tmp1 = find(sm(:,1)<=tw(k,1),1,'last');
        tmp2 = find(sm(:,2)>=tw(k,2),1,'first');
        if isempty(tmp1) && isempty(tmp2)
            out(k) = transition;
            continue;
        elseif isempty(tmp1)
            out(k) = sm(tmp2,3);
            continue;
        elseif isempty(tmp2)
            out(k) = sm(tmp1,3);
            continue;
        end
        if tmp1~=tmp2 && sm(tmp1,3)~=sm(tmp2,3)
            dist1 = sm(tmp1,2)-tw(k,1);
            dist2 = tw(k,2)-sm(tmp2,1);
            if dist1>dist2
                out(k) = sm(tmp1,3);
            elseif dist2>dist1
                out(k) = sm(tmp2,3);
            else
                out(k) = transition;
            end
        else
            out(k) = sm(tmp1,3);
        end
    end
