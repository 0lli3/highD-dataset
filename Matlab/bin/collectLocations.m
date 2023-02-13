% Read in all the csv data and collect the location IDs
clear
run ../initialize.m

inds = 1:2; % the highD file IDs you want to extract lane changes from (in total, there are 60 files)
results_dir = '../results/';
boolSave = true;
boolDisp = false;

laneChangesData = cell(length(inds), 1);
lanesMeta = cell(length(inds), 1);

laneChangesDataStraights = cell(length(inds), 1);
lanesMetaStraights = cell(length(inds), 1);


locationId = zeros(size(inds));
for ind = 1:length(inds)
    if boolDisp
        disp(['Scenario: ', num2str(inds(ind))]);
    end
    if inds(ind) < 10
        videoString = ['0',num2str(inds(ind))];
    else
        videoString = num2str(inds(ind));
    end
    
    recordingMetaFilename = sprintf('../data/%s_recordingMeta.csv', videoString);
    
    csvDataMeta = readtable(recordingMetaFilename, 'Delimiter', ',');
    
    locationId(inds(ind)) = csvDataMeta.locationId;
end

if boolSave
    timeNow = char(datetime('now','Format','yy_MM_dd_HH-mm-ss'));
    if not(isfolder(results_dir))
        mkdir(results_dir)
    end
    filename = [results_dir, timeNow, '_locations.mat'];
    save(filename,'locationId')
end