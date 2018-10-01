animIDs = {'EE12','EE13','EE15','EE16'};
genotypes = {'FF+','FF-','FF+','FF-'};
project_name = 'eeyd_a5GABA_Project';
citadel_path = 'citadel:/volume1/data/Projects/';
local_project_dir = '/media/roshan/ExtraDrive1/Projects/';
data_fetch_paths = strcat(citadel_path,project_name,filesep,animIDs,'_',genotypes,'_Experiment');
data_store_paths = strcat(local_project_dir,project_name,filesep,animIDs,'_',genotypes,'_Experiment');

days = {(1:11);(1:14);(1:12);(1:11)};
tets = {[1,2,3,4,6,7];[1,2,4,5];[1,3,4,6,7,8];[2,3,5,6,8]};
processErr = zeros(1,numel(animIDs));

% For each animal
for k=1:numel(animIDs)
    if sum(processErr==1)>=2
        processErr(k) = 2;
        continue;
    end
    % Pull data from citadel
    pullErr = rsync(data_fetch_paths{k},data_store_paths{k});
    if pullErr~=0
        processErr(k) = -1;
        continue;
    end
    % Run Mountainsort
    rawDir = [data_store_paths{k} filesep animIDs{k}];
    days_to_process = days{k};
    tet_list = tets{k};
    ml_process_animal(animIDs{k},rawDir,'tet_list',tet_list);

    % Push data to citadel
    pushErr = rsync(data_store_paths{k},data_fetch_paths{k});
    if pushErr~=0
        processErr(k) = 1;
        continue;
    end

    % Delete
    delSuccess = rmdir(data_store_paths{k},'s');
    if ~delSuccess
        processErr = 1;
    end
end


function errCode = rsync(fromDir,toDir)
    syncStr = ['rsync -avuPh --progress --exclude="*.rec" --exclude="*.h264" --exclude="@eaDir" --exclude="*.DS_Store" -e ssh ' fromDir '/ ' toDir];
    errCode = system(syncStr,'-echo');
end
