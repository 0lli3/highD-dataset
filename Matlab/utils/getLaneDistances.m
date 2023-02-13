function dist = getLaneDistances(currentCar,...
    currentCarMeta,...
    currentRecordingLanes)

% Get the current car's centre of vehicle positions for all frames
cogCurrentCarXY = calculateCentre(...
    table2array(currentCar(:,{'x','y','width','height'})));

% Depending on the direction of the car, we need to take the lower or upper
% lane markings
if currentCarMeta.drivingDirection == 2
    currentLanes = currentRecordingLanes.lowerLanes;
elseif currentCarMeta.drivingDirection == 1
    currentLanes = currentRecordingLanes.upperLanes;
else
    disp('Error')
end

% Get the index of the first lane which the car is in
laneInd = find(diff(sign(mean(cogCurrentCarXY(:,2)) - currentLanes)));
if currentCarMeta.drivingDirection == 2
    leftLane = currentLanes(laneInd);
    rightLane = currentLanes(laneInd+1);
elseif currentCarMeta.drivingDirection == 1
    leftLane = currentLanes(laneInd+1);
    rightLane = currentLanes(laneInd);
else
    disp('Error')
end

% Calculate the absolute distance between the centre of the vehicle to the
% left and right lane

dist.leftLane = abs(cogCurrentCarXY(:,2) - leftLane);
dist.rightLane = abs(cogCurrentCarXY(:,2) - rightLane);


