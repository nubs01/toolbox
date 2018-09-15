sessionNum = 2;
samplerate = 30000;
min_epoch_break = 1; %seconds
animID = 'RZ9';
% setup directories and file
resDir = '~/Projects/rn_Schizophrenia_Project/RZ9_Df1_Experiment/RZ9_direct/MountainSort/RZ9_02_180814.mountain';
tetDirs = dir([resDir filesep '*.mountain']);
timeFile = dir([resDir filesep '*timestamps*]);
if isempty(timeFile)
    error('No timestamps file found in %s',resDir);
end
timeFile = [timeFile.folder filesep timeFile.name];
timeDat = readmda(timeFile);
saveFile = sprintf('%s%s%sspikes%02i.mat',resDir,filesep,animID,sessionNum);

% Determine epoch start times by looking for gaps longer than 1 sec
gaps = diff(timeDat);
epoch_gaps = find(gaps>=min_epoch_break*samplerate);
epoch_starts = timeDat([1 epoch_gaps]);
Nepochs = numel(epoch_starts);

% get tet numbers
pat = '\w*.nt(?<tet>[0-9]+).\w*';
parsed = cellfun(@(x) regexp(x,pat,'names'),tetDirs);
tet_nums = [parsed.tet];
Ntets = max(tet_nums);

spikes = cell(1,sessionNum);
spikes{sessionNum} = cell(1,Nepochs);
spikes{sessionNum}(:) = {cell(1,Ntets)};

for k=1:numel(tetDirs)
    tD = tetDirs{k};
    % get tet num
    pat = '\w*.nt(?<tet>[0-9]+).\w*';
    parsed = regexp(tD,pat,'names');
    tetNum = str2double(parsed.tet);
    metFile = [tD filesep 'metrics_raw.json'];
    fireFile = [tD filesep 'firings_raw.mda];
    metDat = jsondecode(fileread(metFile));
    metDat = metDat.clusters;
    fireDat = readmda(fireFile); % Rows are # Channels, timestamp (starting @ 0), cluster #

    clusters = [metDat.label];
    Nclust = max(clusters)+any(clusters==0);
    spikes{sessionNum}(:) = {cell(1,Nclust)};
    [clusters,ic] = sort(clusters,'ascend');
    metDat = metDat(ic);

    % TODO: check params.json for smaplerate and error if not matching

    fireTimes = timeDat(fireDat(2,:));
    tmp = cell(1,Nclust);
    for l=1:Nepochs
        for m=1:Nclust
            t1 = epoch_starts(l);
            if l<Nepochs
                t2 = epoch_starts(l+1);
            else
                t2=timeDat(end);
            end
            idx = fireDat(3,:)==clusters(m) & fireTimes>t1 & fireTimes<t2;
            mD = metDat(m).metrics;
            dat = zeros(sum(idx),7);
            fields = 'time x y dir not_used amplitude(highest variance channel) posindex detection_channels';
            descript = 'spike data';
            meanrate = mD.firing_rate;
            peak_amplitude = mD.peak_amplitude;
            refractory_violation_1msec = mD.refractory_violation_1msec;
            dat(:,1) = fireTimes(idx)'/samplerate;
            dat(:,7) = fireDat(1,idx)';
            spikes{sessionNum}{l}{tetNum}{m} = struct('data',dat,'meanrate',meanrate,...
                                                'descript',descript,'fields',fields,...
                                                'timerange',[t1 t2]/samplerate,...
                                                'tag','',...
                                                'peak_amplitude',peak_amplitude,...
                                                'refractory_violation_1msec',...
                                                refractory_violation_1msec);
        end
    end
end

save(saveFile,'spikes');   


