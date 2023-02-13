function [metaData, data, metaData_others, data_others] = ...
    readInLaneChangeCsv(filename, filenameStatic, filenameRecMeta,...
    maxDist, minFrames, maxStraights, boolLaneChange, boolDisp)

assert(islogical(boolLaneChange))

% Read the csv and convert it into a table
csvData = readtable(filename, 'Delimiter', ',');
csvDataStatic = readtable(filenameStatic, 'Delimiter', ',');
csvDataMeta = readtable(filenameRecMeta, 'Delimiter', ',');

% Since we only have one set of lanes for a single recording, we can
% extract the data here
currentRecordingLanes.upperLanes = str2num(...
    csvDataMeta.upperLaneMarkings{:});
currentRecordingLanes.lowerLanes = str2num(...
    csvDataMeta.lowerLaneMarkings{:});

% Get the Ids of the cars which change lane
% First, only consider the cars with one lane change
if boolLaneChange
    num_lane_changes = 1;
    laneChangeIds = csvDataStatic.id(...
        csvDataStatic.numLaneChanges == num_lane_changes & ...
        csvDataStatic.numFrames >= minFrames);
else
    laneChangeIds = csvDataStatic.id(...
        csvDataStatic.numLaneChanges == 0 &...
        csvDataStatic.numFrames >= minFrames);
    laneChangeIds = sort(laneChangeIds(randperm(length(laneChangeIds),...
        maxStraights)));
end

% Loop through all cars with a lane change
laneChanges = 1;
data = {};
data_others = {};
metaData = {};
metaData_others = {};

% Extract the current right most and left most lane ids
lane_ids = unique(csvData.laneId(:));
if ~mod(length(lane_ids),2)
    right_lanes = [lane_ids(1), lane_ids(end)];
    middle_lane = (length(lane_ids)/2);
    left_lanes = [lane_ids(middle_lane), lane_ids(middle_lane + 1)];
else
    % Some highways were recorded with an additional lane on the top, i.e.,
    % the highway ramp was also recorded.  Therefore, we will take the ramp
    % as the right most lane for direction right->left and calculate the
    % muddle lanes slightly differently.
    right_lanes = [lane_ids(1), lane_ids(end)];
    middle_lane = (length(lane_ids) + 1)/2;
    left_lanes = [lane_ids(middle_lane), lane_ids(middle_lane + 1)];
end

if boolDisp
    disp(['Number of events: ', num2str(length(laneChangeIds))])
end
for carId = laneChangeIds.'
    if boolDisp
        disp(['LaneChange: ', num2str(laneChanges), '/',...
            num2str(length(laneChangeIds))]);
    end
    % Take all the frames with the car labeled as carId
    currentCar = csvData(csvData.id == carId,:);
    currentCarStatic = csvDataStatic(csvDataStatic.id == carId,:);
    currentCarMeta = csvDataMeta(csvDataMeta.id == carId,:);
    % Remove all data after the lane change or take maxFrames frames
    % This method does not work any more since the lane index does not
    % change until the upper left corner of the vehicle is on the new lane
    % Instead we need to calculate the frame in which the center of the car
    % crosses the lane.  In the end, it turns out that the highD
    % pre-processing also takes the centre of the vehicle to calculate when
    % the car changes lane.
    %     lastFrame = getLaneChangeFrame(currentCar,...
    %         currentCarMeta,...
    %         currentRecordingLanes);
    
    if boolLaneChange
        currentCarAfter = currentCar(currentCar.laneId == currentCar.laneId(1),:);
    else
        currentCarAfter = currentCar(1:minFrames,:);
    end
    
    % Check that we have enough frames to create training data, if we do
    % not have at least minFrames (e.g. 125 frames) then we cannot create a
    % training sample from this vehicle.
    if size(currentCarAfter,1) < minFrames
        if boolDisp
            disp('Car not in frame long enough.')
        end
        continue;
    end
    
    % Calculate distances to other vehicles
    % preceding car in same lane
    positions = [{'precedingId'},{'followingId'},{'leftPrecedingId'},...
        {'rightPrecedingId'},{'leftFollowingId'},{'rightFollowingId'},...
        {'leftAlongsideId'},{'rightAlongsideId'}];
    d = getDistance(currentCarAfter,...
        csvData,...
        positions,...
        maxDist,...
        left_lanes,...
        right_lanes);
    
    if islogical(d)
        if boolDisp
            disp(['Inconsistant tracking for CarId: ', num2str(carId)])
        end
        continue;
    end
    
    % Save the current vehicle ID
    data(laneChanges).id = carId;
    % Collect the other car IDs
    otherIds = [];
    for position = positions
        otherIds = [otherIds; unique(currentCar{currentCar{:, position{:}} > 0, position{:}},...
            'stable')];
    end
    otherIds = unique(otherIds);
    data(laneChanges).otherIds = unique(otherIds);
    % Save the frames which the vehicle was present
    data(laneChanges).frames = currentCarAfter.frame;
    % Save the time length of the data
    data(laneChanges).length = length(currentCarAfter.xVelocity);
    % Collect the data from the current car
    data(laneChanges).vx_abs = abs(currentCarAfter.xVelocity);
    data(laneChanges).vy_abs = currentCarAfter.yVelocity;
    
    % We need to check whether the cars are driving left -> right or
    % right -> left, becuase the acceleration direction is flipped in the
    % global system for cars driving left -> right (drivingDirection == 1)
    if currentCarStatic.drivingDirection == 1
        data(laneChanges).ax = -(currentCarAfter.xAcceleration);
        data(laneChanges).ay = -(currentCarAfter.yAcceleration);
        data(laneChanges).vx = -(currentCarAfter.xVelocity);
        data(laneChanges).vy = -(currentCarAfter.yVelocity);
    else
        data(laneChanges).ax = (currentCarAfter.xAcceleration);
        data(laneChanges).ay = (currentCarAfter.yAcceleration);
        data(laneChanges).vx = (currentCarAfter.xVelocity);
        data(laneChanges).vy = (currentCarAfter.yVelocity);
    end
    
    % Save the distances from the current car to the other cars
    f = fieldnames(d);
    for i = 1:length(f)
        data(laneChanges).(f{i}) = d.(f{i});
    end
    
    % Get the distance to the lane marking for the currentCar
    laneDistances = getLaneDistances(currentCarAfter,...
        currentCarStatic,...
        currentRecordingLanes);
    
    data(laneChanges).dist_left_lane = laneDistances.leftLane;
    data(laneChanges).dist_right_lane = laneDistances.rightLane;
    
    % Store the DHW, THW and TTC, which might be interesting features for
    % later
    data(laneChanges).dhw = currentCarAfter.dhw;
    data(laneChanges).thw = currentCarAfter.thw;
    data(laneChanges).ttc = currentCarAfter.ttc;
    
    %     Save boolean whether this vehicle was a car or a truck
    data(laneChanges).boolCar = strcmp(currentCarStatic.class, 'Car');
    
    % Check whether the lane change was right or left
    metaData(laneChanges).id = carId;
    metaData(laneChanges).direction = sign(currentCar.xVelocity(1));
    metaData(laneChanges).drivingDirection = currentCarStatic.drivingDirection;
    metaData(laneChanges).lanes = unique(currentCar.laneId, 'stable');
    if boolLaneChange
        if metaData(laneChanges).drivingDirection == 1
            if metaData(laneChanges).lanes(1) < metaData(laneChanges).lanes(2)
                metaData(laneChanges).change = 'left';
            else
                metaData(laneChanges).change = 'right';
            end
        elseif metaData(laneChanges).drivingDirection == 2
            if metaData(laneChanges).lanes(1) < metaData(laneChanges).lanes(2)
                metaData(laneChanges).change = 'right';
            else
                metaData(laneChanges).change = 'left';
            end
        end
    else
        metaData(laneChanges).change = 'straight';
    end
    % Store the location of the current sample
    metaData(laneChanges).locationID = currentCarMeta.locationId;
    
    
    
    %% Calculate the training data of the other cars in the scenario
    % Collect Ids of other cars in the scenario
    for i = 1:length(otherIds)
        
        % Get the Meta data for the other vehicle
        otherCarStatic = csvDataStatic(csvDataStatic.id == otherIds(i),:);
        
        % First check that the other car does not change lane
        if otherCarStatic.numLaneChanges > 0
            if boolDisp
                disp(['Other car in scenario also changes lane, CarId: ',...
                    num2str(otherIds(i))]);
            end
            continue;
        end
        
        % Extract the frames where the other car and current car are in the
        % scenario together.
        otherCar = csvData(csvData.id == otherIds(i), :);
        [otherCarInds, ~] = ismember(otherCar.frame, currentCarAfter.frame);
        otherCar = otherCar(otherCarInds, :);
        
        % Check that we will have enough frames and that the scenario ends
        % on the same frame.  In the end we want to take the cars from the
        % same scenario, where currentCar changes lane and all other cars
        % drive straight.
        if sum(otherCarInds) < minFrames
            if boolDisp
                disp(['Other car is not in the scenario long enough, CarId: ',...
                    num2str(otherIds(i))]);
            end
            continue;
        elseif otherCar.frame(end) ~= currentCarAfter.frame(end)
            if boolDisp
                disp(['Other car is not in the scenario when currentCar ',...
                    'changes lane, CarId: ', num2str(otherIds(i))]);
            end
            continue;
        end
        
        
        d = getDistance(otherCar,...
            csvData,...
            positions,...
            maxDist,...
            left_lanes,...
            right_lanes);
        
        if islogical(d)
            if boolDisp
                disp(['Inconsistant tracking for CarId: ', num2str(carId)])
            end
            continue;
        end
        
        otherSaveInd = size(data_others, 2) + 1;
        % Save the other vehicle ID
        data_others(otherSaveInd).id = otherIds(i);
        % Save the current vehicle ID
        data_others(otherSaveInd).otherIds = carId;
        % Save the frames which the vehicle was present
        data_others(otherSaveInd).frames = otherCar.frame;
        % Save the time length of the data
        data_others(otherSaveInd).length = length(otherCar.xVelocity);
        % Collect the data from the current car
        data_others(otherSaveInd).vx_abs = abs(otherCar.xVelocity);
        data_others(otherSaveInd).vy_abs = abs(otherCar.yVelocity);
        
        % We need to check whether the cars are driving left -> right or
        % right -> left, becuase the acceleration direction is flipped in the
        % global system for cars driving left -> right (drivingDirection == 1)
        if otherCarStatic.drivingDirection == 1
            data_others(otherSaveInd).ax = -(otherCar.xAcceleration);
            data_others(otherSaveInd).ay = -(otherCar.yAcceleration);
            data_others(otherSaveInd).vx = -(otherCar.xVelocity);
            data_others(otherSaveInd).vy = -(otherCar.yVelocity);
        else
            data_others(otherSaveInd).ax = (otherCar.xAcceleration);
            data_others(otherSaveInd).ay = (otherCar.yAcceleration);
            data_others(otherSaveInd).vx = (otherCar.xVelocity);
            data_others(otherSaveInd).vy = (otherCar.yVelocity);
        end
        % Save the distances from the current car to the other cars
        f = fieldnames(d);
        for dd = 1:length(f)
            data_others(otherSaveInd).(f{dd}) = d.(f{dd});
        end
        
        % Get the distance to the lane marking for the otherCars, from the
        % same scenario who are driving straight
        laneDistances = getLaneDistances(otherCar,...
            otherCarStatic,...
            currentRecordingLanes);
        
        data_others(otherSaveInd).dist_left_lane = laneDistances.leftLane;
        data_others(otherSaveInd).dist_right_lane = laneDistances.rightLane;
        
        % Store the DHW, THW and TTC, which might be interesting features for
        % later
        data_others(otherSaveInd).dhw = otherCar.dhw;
        data_others(otherSaveInd).thw = otherCar.thw;
        data_others(otherSaveInd).ttc = otherCar.ttc;
        
        % Save boolean whether the vehicle is a car or truck
        data_others(otherSaveInd).boolCar = strcmp(otherCarStatic.class, 'Car');
        
        % Store the Meta data for the other vehicle
        % Check whether the lane change was right or left
        metaData_others(otherSaveInd).id = otherIds(i);
        metaData_others(otherSaveInd).direction = sign(otherCar.xVelocity(1));
        metaData_others(otherSaveInd).drivingDirection = otherCarStatic.drivingDirection;
        metaData_others(otherSaveInd).lanes = unique(otherCar.laneId, 'stable');
        metaData_others(otherSaveInd).change = 'straight';
        
        
    end
    
    % Increase the laneChanges index
    laneChanges = laneChanges + 1;
end

% We want to make sure that we have a balanced dataset, so we will
% take at most the same number of straights as we have lefts and rights
num_straights = size(metaData_others, 2);
if  num_straights > laneChanges - 1
    % Sample random straights from all scenarios
    inds = randperm(num_straights, laneChanges - 1);
    
    % Overwrite the number of straights with the randomly selected
    % scenarios
    data_others = data_others(inds);
    metaData_others = metaData_others(inds);
end

end