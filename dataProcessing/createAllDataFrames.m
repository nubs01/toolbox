function out = createAllDataFrames(animID,varargin)

    delta_band = [0 5];
    winSize = 2;
    winStep = 2;
    band_names = {'delta','theta'};
    bands = {[0 5],[6 10]};
    dataDir = [get_data_path('sz_data',animID) filesep animID '_direct'];
    assignVars(varargin)

    % Identifiers: animID, genotype, gender, day, epoch, tetrode, epoch_type, age
    animDat = getAnimMetadata(animID);
    recDays = [animDat.recording_data.day];

    ketFile = sprintf('%s%s%sdeltaTraceMatrix.csv',dataDir,filesep,animID);
    specFile = sprintf('%s%s%ssleepSpecMatrix.csv',dataDir,filesep,animID);
    bandFile = sprintf('%s%s%ssleepBandPowerMatrix',dataDir,filesep,animID);

    %% Ketamine data frame
    % time from epoch start, delta power norm to sleep epoch mean (1 sec bins)
    ketHead = {'animal','genotype','gender','day','epoch','tetrode','epoch_type','age','epoch_time','sleep_state','STFT_delta_power','CWT_delta_power'};

    %% Baseline Analysis (Sleep Epoch Only)
    % Spectra: time from epoch start, frequency, STFT power, CWT power (1 sec non-overlaping windows)
    specHead = {'animal','genotype','gender','day','epoch','tetrode','epoch_type','age','epoch_time','sleep_state','frequency','STFT_Power','CWT_Power'};

    % Band Power: band, CWT (mean, median, total & normalized mean), STFT (same) 
    bandHead = {'animal','genotype','gender','day','epoch','tetrode','epoch_type','age','epoch_time','sleep_state','power_band','STFT_mean','STFT_median','STFT_total','STFT_norm_mean','CWT_mean','CWT_median','CWT_total','CWT_norm_mean'};
    sleepDelta_cwt = cell(1,numel(recDays));
    sleepDelta_stft = cell(1,numel(recDays));

    kid = fopen(ketFile,'w');
    sid = fopen(specFile,'w');
    bid = fopen(bandFile,'w');

    write_to_csv(kid,ketHead);
    write_to_csv(sid,specHead);
    write_to_csv(bid,bandHead);

    for k=1:numel(recDays)
        recDat = animDat.recording_data(k);
        dd = recDat.day;
        fprintf('Processing day %02i...\n',dd)
        tetInfo = recDat.tet_info;
        riptets = find([tetInfo.riptet] & ~[tetInfo.exclude]);
        epochs = [recDat.epochs.epoch];
        states = get_ff_data(animID,'states',dd,'subFolder','SleepStates');
        sleepDelta_cwt{dd} = cell(1,max(riptets));
        sleepDelta_stft{dd} = cell(1,max(riptets));

        for m=1:numel(epochs)
            epochDat = recDat.epochs(m);
            ee = epochDat.epoch;
            fprintf('   - Processing epoch %02i...\n',ee)
            epoch_type = epochDat.epoch_type;
            stateMat = states{ee}.state_mat;
            stateNames = states{ee}.state_names;
            ignoreStates = find(strcmpi(stateNames,'Transition') | strcmpi(stateNames,'Artifact'));
            rawTime = stateMat(1,1)+winSize/2:winStep:stateMat(end,2)-winSize/2;
            epoTime = winSize/2:winStep:(stateMat(end,2)-stateMat(1,1)-winSize/2);
            stateVec = getStateVec(stateMat,rawTime);
            ignoreIdx = arrayfun(@(x) any(x==ignoreStates),stateVec);

            for l=1:numel(riptets)
                tetDat = tetInfo(riptets(l));
                tt = tetDat.tetrode;
                fprintf('       - Grabbing tetrode %02i...\n',tt)

                ID = {animID,animDat.genotype,animDat.gender,dd,ee,tt,epoch_type,recDat.age};

                cwtspec = get_ff_data(animID,'cwtspecgram',dd,ee,tt,'subFolder','Spectrograms');
                freq1 = cwtspec.frequency;
                stftspec = get_ff_data(animID,'spectra',dd,ee,tt,'subFolder','Spectra');
                freq2 = stftspec.frequency;
                if max(freq1)<max(freq2)
                    frequency = freq1;
                else
                    frequency = freq2;
                end
                delta_idx = (frequency>=delta_band(1) & frequency<=delta_band(2));

                % Massage spectra into correct format
                % remove overlapping windows, interpolate to match times & frequencies
                % remove artifacts
                fprintf('       - Correcting Spectrograms\n')
                oldCWT.spec = cwtspec.spectrogram;
                oldCWT.time = cwtspec.window_centers;
                oldCWT.freq = cwtspec.frequency;
                newCWT = fixSpec(oldCWT,rawTime,frequency,ignoreIdx);

                oldSTFT.spec = stftspec.windowed_spectra;
                oldSTFT.time = stftspec.window_centers;
                oldSTFT.freq = stftspec.frequency;
                newSTFT = fixSpec(oldSTFT,rawTime,frequency,ignoreIdx);

                if strcmpi(epoch_type,'Sleep')
                    sleepDelta_cwt{dd}{tt} = mean(newCWT.mean_spec(delta_idx));
                    sleepDelta_stft{dd}{tt} = mean(newSTFT.mean_spec(delta_idx));
                end
                fprintf('       - Appending to  dataframes...\n')

                if ~strcmpi(epoch_type,'Home')
                    deltaVecCWT = mean(newCWT.spec(delta_idx,:),1)'./sleepDelta_cwt{dd}{tt};
                    deltaVecSTFT = mean(newSTFT.spec(delta_idx,:),1)'./sleepDelta_stft{dd}{tt};
                    ketCell = [repmat(ID,numel(rawTime),1) num2cell(epoTime') num2cell(stateVec) num2cell(deltaVecSTFT) num2cell(deltaVecCWT)];
                    write_to_csv(kid,ketCell);
                end

                if strcmpi(epoch_type,'Sleep') || strcmpi(epoch_type,'Home')
                    for n=1:numel(rawTime)
                        nF = numel(frequency);
                        tmp = [repmat([epoTime(n) stateVec(n)],nF,1) frequency' newSTFT.spec(:,n) newCWT.spec(:,n)];
                        specCell = [repmat(ID,size(tmp,1),1) num2cell(tmp)];
                        write_to_csv(sid,specCell);

                        clear tmp
                        stft_norm = sum(newSTFT.mean_spec);
                        cwt_norm = sum(newCWT.mean_spec);
                        for o=1:numel(band_names)
                            band_idx = (frequency>=bands{o}(1) & frequency<=bands{o}(2));

                            stft_power = newSTFT.spec(band_idx,n);
                            cwt_power = newCWT.spec(band_idx,n);
                            tmp = {epoTime(n) stateVec(n) band_names{o} mean(stft_power) median(stft_power) sum(stft_power) sum(stft_power)/stft_norm mean(cwt_power) median(cwt_power) sum(cwt_power) sum(cwt_power)/cwt_norm};
                            bandCell = [repmat(ID,size(tmp,1),1) tmp];
                            write_to_csv(bid,bandCell);
                        end
                    end
                end
            end
        end
    end

    fclose(kid);
    fclose(sid);
    fclose(bid);


    out = {ketFile;specFile;bandFile};


function out=getStateVec(stateMat,rawTime)
    out = zeros(numel(rawTime),1);
    for k=1:numel(rawTime)
        idx = find(stateMat(:,1)<=rawTime(k) & stateMat(:,2)>=rawTime(k));
        if numel(idx)==2
            t1 = stateMat(idx(1),2)-stateMat(idx(1),1);
            t2 = stateMat(idx(2),2)-stateMat(idx(2),1);
            if t1>t2
                idx = idx(1);
            else
                idx = idx(2);
            end
        end
        if isempty(idx) || numel(idx)>1
            error('WTF')
        end
        out(k) = stateMat(idx,3);
    end

function out=fixSpec(oldSpec,newTime,newFreq,ignoreIdx)
    tmpSpec = zeros(numel(oldSpec.freq),numel(newTime));

    % interp over time for each freq
    for k=1:numel(oldSpec.freq)
        tmpSpec(k,:) = interp1(oldSpec.time,abs(oldSpec.spec(k,:)),newTime,'linear','extrap');
    end

    outSpec = zeros(numel(newFreq),numel(newTime));
    % interp over freq for each time
    for k=1:numel(newTime)
        outSpec(:,k) = interp1(oldSpec.freq,tmpSpec(:,k),newFreq,'linear','extrap');
    end
    out.spec = outSpec;
    out.time = newTime;
    out.freq = newFreq;
    out.mean_spec = mean(outSpec(:,~ignoreIdx),2);

function write_to_csv(fid,dataCell)
    for k=1:size(dataCell,1)
        tmp = cellfun(@num2str,dataCell(k,:),'UniformOutput',false);
        outStr = strjoin(tmp,',');
        fprintf(fid,[outStr '\n']);
    end
