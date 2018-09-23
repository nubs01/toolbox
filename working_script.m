sessionNum = 2;
samplerate = 30000;
animID = 'RZ9';
% setup directories and file
resDir = '~/Projects/rn_Schizophrenia_Project/RZ9_Df1_Experiment/RZ9_direct/MountainSort/RZ9_02_180814.mountain';
rawDir =  '~/Projects/rn_Schizophrenia_Project/RZ9_Df1_Experiment/RZ9/02_180814/';
matclustDir = [rawDir 'RZ9_02_180814.matclust/'];

epoch = 1;
tet = 8;

% get matclust params for plotting
paramFile = sprintf('%sparam_nt%i.mat',matclustDir,tet);
filedata = load(paramFile);
filedata = filedata.filedata;
mc_times = filedata.params(:,1);

% pick the 3 params with the highest variance
parVar = var(filedata.params);
[~,iv] = sort(parVar,'descend');
bestParams = iv(2:4);



