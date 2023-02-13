clear;
load('../results/23_02_10_14-02-37_laneChanges_100Frames.mat')
load('../results/23_02_10_14-05-02_locations.mat')
% This version allows you to extract both the Straights and the lane
% changes
% Set the maximum number of frames
num_frames = 100; % number of frames we consider (should be at <= minFrames in collectLaneChanges.m)
num_features = 12;
% We also want to store the features and their order in case this
% information is required later
logitOrder = [{'vx'},...
    {'vy'},...
    {'ax'},...
    {'ay'},...
    {'d_right_front'},...
    {'d_right_rear'},...
    {'d_front'},...
    {'d_rear'},...
    {'d_left_front'},...
    {'d_left_rear'},...
    {'dist_left_lane'},...
    {'dist_right_lane'}];
bool_Only_Cars = false;
bool_Save = true;
% Just check how many scenarios were extracted
scenariosInds = find(~cellfun('isempty', laneChangesData));
num_scenarios = size(scenariosInds, 1);
% Set this boolean if you want to randomly shuffle the training data so
% that all the straights are not right at the end.
bool_random_order = true;
date_now = '20_03_24';
save_name = ['../results/', date_now, '_highD_', num2str(num_frames),'.mat'];
save_name_meta = ['../results/', date_now, '_highD_', num2str(num_frames),'_meta.mat'];
save_name_frames = ['../results/', date_now, '_highD_', num2str(num_frames),'_frames.mat'];

% If we only extracted data from less than the total number of scenarios,
% we overwrite the saved data

%% Loop through the different locations and extract the data from each loaction
locations = unique(locationId);
% Update the location IDs for all samples
for i = 1:length(locationId)
    for jj = 1:length(lanesMeta{i})
        lanesMeta{i}(jj).locationID = i;
        lanesMetaStraights{i}(jj).locationID = i;
    end
end


% Extract only the lane changes with more than num_frames time frames
tmp = [[laneChangesData{:,1}],...
    [laneChangesDataStraights{:,1}]];
tmp1 = [[lanesMeta{:,1}],...
    [lanesMetaStraights{:,1}]];
% Only extract the scenarios with cars if the boolean bool_Only_Cars is
% true
if bool_Only_Cars
    laneChanges = tmp([tmp.length] >= num_frames &  [tmp.boolCar]);
    laneChangeMeta = tmp1([tmp.length] >= num_frames & [tmp.boolCar]);
else
    laneChanges = tmp([tmp.length] >= num_frames);
    laneChangeMeta = tmp1([tmp.length] >= num_frames);
end

% Free up some space
% clear('tmp')
% clear('tmp1')

% Find the indices with the lane changes
ind_rights = cellfun(@(x) strcmp(x, 'right'), {laneChangeMeta.change},...
    'UniformOutput', 1);
ind_lefts = cellfun(@(x) strcmp(x, 'left'), {laneChangeMeta.change},...
    'UniformOutput', 1);
ind_straights = cellfun(@(x) strcmp(x, 'straight'), {laneChangeMeta.change},...
    'UniformOutput', 1);

% Display the number of left, right and straights
disp(['# Lefts: ', num2str(sum(ind_lefts))])
disp(['# Rights: ', num2str(sum(ind_rights))])
disp(['# Straights: ', num2str(sum(ind_straights))])

% Get the number of samples after filtering out with frame length >=
% num_frames
num_samples = size(laneChanges, 2);


% Preallocate matrices to store the samples
logits = zeros(num_frames, num_features, num_samples);
labels = zeros(1, num_samples);
cars = zeros(1, num_samples);
% Make sure that the number of features is the same as the length of the
assert(length(logitOrder) == num_features);

% Store the frames which each sample was visible and the location ID
frames = zeros(3, num_samples);
% Extract the features from the samples
for i = 1:num_samples
    sample = laneChanges(i);
    % Extract the features we want from the same and only take the
    % num_frames starting at the end of the scenario
    for j = 1:length(logitOrder)
        tmp = sample.(logitOrder{j});
        if size(tmp,2) > 1
            logits(:,j,i) = tmp(end-num_frames+1:end, 1);
        else
            logits(:,j,i) = tmp(end-num_frames+1:end);
        end
    end
    % Count how many cars vs trucks we had
    cars(i) = sample.boolCar;
    
    % Store the frames information
    frames(1, i) = sample.frames(1);
    frames(2, i) = sample.frames(end);
    frames(3, i) = sample.id;
    frames(4, i) = laneChangeMeta(i).locationID;
end

% Store the labels
labels(ind_rights) = -1;
labels(ind_lefts) = +1;
labels(ind_straights) = 0;

labelOrder = [{'Right = -1'},...
    {'Left = +1'},...
    {'Straight = 0'}];

if bool_random_order
    % Randomly shuffle the data so we don't have all of the straights at the
    % end
    rand_inds = randperm(num_samples);
    logits = logits(:, :, rand_inds);
    labels = labels(rand_inds);
    frames = frames(:, rand_inds);
end

if bool_Save
    save(save_name, 'logits', 'labels');
    save(save_name_meta, 'logitOrder', 'labelOrder');
    save(save_name_frames, 'frames');
end

