% Read in all the csv data and collect the lane changes
clear
run ../initialize.m

maxDist = 200; % maximum distance between vehicles
minFrames = 100; % minimum number of frames we want to consider
maxStraights = 115; % maximum number of straights per scenario
inds = 1:2; % the highD file IDs you want to extract lane changes from (in total, there are 60 files)
results_dir = '../results/';
boolSave = true;
boolDisp = false;

laneChangesData = cell(length(inds), 1);
lanesMeta = cell(length(inds), 1);

laneChangesDataStraights = cell(length(inds), 1);
lanesMetaStraights = cell(length(inds), 1);

% Run through the scenarios
for ind = 1:length(inds)
    if boolDisp
        disp(['Scenario: ', num2str(inds(ind))]);
    end
    if inds(ind) < 10
        videoString = ['0',num2str(inds(ind))];
    else
        videoString = num2str(inds(ind));
    end
    
    tracksFilename = sprintf('../data/%s_tracks.csv', videoString);
    tracksStaticFilename = sprintf('../data/%s_tracksMeta.csv', videoString);
    recordingMetaFilename = sprintf('../data/%s_recordingMeta.csv', videoString);
    
    % Collect the lane change data from the current CSV file
    [metaData, laneChanges, metaDataOthers, trainingDataOthers] = ...
        readInLaneChangeCsv(tracksFilename,...
        tracksStaticFilename,...
        recordingMetaFilename,...
        maxDist,...
        minFrames,...
        maxStraights,...
        true,...
        boolDisp);
    
    laneChangesData{ind, 1} = laneChanges;
    lanesMeta{ind, 1} = metaData;
    laneChangesDataStraights{ind, 1} = trainingDataOthers;
    lanesMetaStraights{ind, 1} = metaDataOthers;
    
end

if boolSave
    timeNow = char(datetime('now','Format','yy_MM_dd_HH-mm-ss'));
    if not(isfolder(results_dir))
        mkdir(results_dir)
    end
    filename = [results_dir, timeNow, '_laneChanges_', num2str(minFrames),'Frames.mat'];
    save(filename,'laneChangesData', 'lanesMeta',...
        'laneChangesDataStraights','lanesMetaStraights')
end