function lastFrame = getLaneChangeFrame(currentCar,...
    currentCarMeta,...
    currentRecordingLanes)

% Get the current car's centre of vehicle positions for all frames
cogCurrentCarXY = calculateCentre(...
    table2array(currentCar(:,{'x','y','width','height'})));

% Depending on the direction of the car, we need to take the lower or upper
% lane markings
if currentCarMeta.drivingDirection == 2
    currentLanes = currentRecordingLanes.lowerLanes(2:end-1);
elseif currentCarMeta.drivingDirection == 1
    currentLanes = currentRecordingLanes.upperLanes(2:end-1);
else
    disp('Error')
end

% We want to find the frame in which the centre of the vehicle crosses the
% lane
laneChange = zeros(size(currentLanes));
for i = 1:length(currentLanes)
    % Take the sign of the difference to the lane
    difference = sign(cogCurrentCarXY(:,2) - currentLanes(i));
    % If there is a frame where the centre of the car is on the line, then
    % we can take that index
    ind = find(difference == 0);
    if ~isempty(ind)
        laneChange(i) = ind(1);
        continue
    end
    % Otherwise, check for the sign change in the differences, i.e.,
    % a frame where the car changed lanes
    ind = find(diff(difference));
    if ~isempty(ind)
        laneChange(i) = ind(1);
    end
end

% Get the frame index from the currentCar data and compare this with the
% laneChange index which was just found
% laneChangeMeta = find(currentCar.laneId(:) == currentCar.laneId(1),1,'last');
lastFrame = max(laneChange);
end