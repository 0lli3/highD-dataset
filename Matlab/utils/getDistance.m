function data = getDistance(currentCar, csvData, positions, max_dist, left_lanes, right_lanes)

% Loop through all the positions
for position = positions
    ids = unique(currentCar{currentCar{:, position{:}} > 0, position{:}},...
        'stable');
    
    % First initialise a matrix of all max_distances, i.e., where there
    % are no vehicles in the scenario
    d = [ones(size(currentCar,1),1), ...
        zeros(size(currentCar,1),1)];
    d(:, 1) = max_dist * d(:, 1);
    if ~isempty(ids)
        for i = 1:length(ids)
            bool_with_other = currentCar{:, position{:}} == ids(i);
            frames_with_other = currentCar{bool_with_other, 'frame'};
            otherCar = csvData(csvData.id == ids(i),:);
            
            currentXY = table2array(currentCar(bool_with_other,...
                {'x','y','width','height'}));
            currentXY_cog = calculateCentre(currentXY);
            
            [~,otherCarInds] = ismember(frames_with_other, otherCar.frame);
            otherXY = table2array(otherCar(otherCarInds, ...
                {'x','y','width','height'}));
            
            otherXY_cog = calculateCentre(otherXY);
            
            % Calculate the distance between the two vehicles
            d_tmp = diag(sqrt((currentXY_cog - otherXY_cog)*...
                (currentXY_cog - otherXY_cog).'));
            d(bool_with_other, 1) = d_tmp;
            d(bool_with_other, 2) = ids(i);
            
            
            % Since one car can be along side multiple times, we have
            % to check how many start and end indices there are over
            % the time frames.
            if strcmp(position, 'leftAlongsideId') ||...
                    strcmp(position, 'rightAlongsideId')
                ind_with_other = find(diff(bool_with_other));
                if bool_with_other(1)
                    ind_with_other = [0; ind_with_other];
                elseif bool_with_other(end)
                    ind_with_other = [ind_with_other; length(bool_with_other)];
                end
                start_inds = ind_with_other(1:2:end)+1;
                end_inds = ind_with_other(2:2:end);
            end
            
            % If we are looking at the alongside positions then we need to
            % overwrite either the front or rear vehicle
            % Actually, we should overwrite both the front and rear
            % vehicle, because otherwise there is an inconistency with the
            % distances.  Once a vehicle passes the currentCar, it should
            % be added to the left_rear
            if strcmp(position, 'leftAlongsideId')
                for nn = 1:length(ind_with_other)/2
                    savedAlong = false;
                    start_ind = start_inds(nn);
                    end_ind = end_inds(nn);
                    range_ind = start_ind:end_ind;
                    % find the time stamps where the car is alongside left
                    %                     ind_with_other = find(bool_with_other);
                    % get the index with the minimum distance - this is the
                    % time point where the cars pass each other
                    [~, min_ind] = min(d(range_ind,1));
                    
                    % Extract the distances before and after the two
                    % vehicles pass each other
                    after_inds = range_ind(min_ind):end_ind;
                    before_inds = start_ind:range_ind(min_ind)-1;
                    afterT0 = d(after_inds,1);
                    beforeT0 = d(before_inds,1);
                    % Check the front vehicles
                    if end_ind ~= length(bool_with_other) && ...
                            data.d_left_front(end_ind+1,2) == ids(i)
                        savedAlong = true;
                        % This situation describes when ids(i) overtakes
                        % the currentCar from the left
                        % Then we overwrite the left front
                        data.d_left_front(after_inds,1)=...
                            afterT0;
                        data.d_left_front(after_inds,2)=...
                            ids(i);
                        % First we overwrite the left rear
                        data.d_left_rear(before_inds,1)=...
                            beforeT0;
                        data.d_left_rear(before_inds,2)=...
                            ids(i);
                    end
                    if start_ind ~= 1 && ...
                            data.d_left_front(start_ind-1,2) == ids(i)
                        % This situation describes when currentCar overtakes
                        % the ids(i) from the left 
                        savedAlong = true;
                        % First we overwrite the front left
                        data.d_left_front(before_inds,1)=...
                            beforeT0;
                        data.d_left_front(before_inds,2)=...
                            ids(i);
                        % Then we overwrite the rear left
                        data.d_left_rear(after_inds,1)=...
                            afterT0;
                        data.d_left_rear(after_inds,2)=...
                            ids(i);
                    end
                    
                    % Check the rear vehicles
                    if end_ind ~= length(bool_with_other) && ...
                            data.d_left_rear(end_ind+1,2) == ids(i)
                        savedAlong = true;
                        
                        % This situation describes when currentCar overtakes
                        % the ids(i) from the left
                        % First we overwrite the front left
                        data.d_left_front(before_inds,1)=...
                            beforeT0;
                        data.d_left_front(before_inds,2)=...
                            ids(i);
                        % Then we overwrite the rear left
                        data.d_left_rear(after_inds,1)=...
                            afterT0;
                        data.d_left_rear(after_inds,2)=...
                            ids(i);
                    end
                    if start_ind ~= 1 && ...
                            data.d_left_rear(start_ind-1,2) == ids(i)
                        savedAlong = true; 
                        % This situation describes when ids(i) overtakes
                        % the currentCar from the left
                        data.d_left_front(after_inds,1)=...
                            afterT0;
                        data.d_left_front(after_inds,2)=...
                            ids(i);
                        % First we overwrite the left rear
                        data.d_left_rear(before_inds,1)=...
                            beforeT0;
                        data.d_left_rear(before_inds,2)=...
                            ids(i);
                    end
                   
                    if ~savedAlong
                        data = false;
                        return
                    end
                    
                end
                
            end
            
            % If we are looking at the alongside positions then we need to
            % overwrite either the front or rear vehicle
            if strcmp(position, 'rightAlongsideId')               
                for nn = 1:length(ind_with_other)/2
                    savedAlong = false;
                    start_ind = start_inds(nn);
                    end_ind = end_inds(nn);
                    range_ind = start_ind:end_ind;
                    % find the time stamps where the car is alongside left
                    %                     ind_with_other = find(bool_with_other);
                    % get the index with the minimum distance - this is the
                    % time point where the cars pass each other
                    [~, min_ind] = min(d(range_ind,1));
                    
                    % Extract the distances before and after the two
                    % vehicles pass each other
                    after_inds = range_ind(min_ind):end_ind;
                    before_inds = start_ind:range_ind(min_ind)-1;
                    afterT0 = d(after_inds,1);
                    beforeT0 = d(before_inds,1);
                
                    % Check the front vehicles
                    if end_ind ~= length(bool_with_other) && ...
                            data.d_right_front(end_ind+1,2) == ids(i)
                        savedAlong = true;
                        
                        data.d_right_front(after_inds,1)=...
                            afterT0;
                        data.d_right_front(after_inds,2)=...
                            ids(i);
                        data.d_right_rear(before_inds,1)=...
                            beforeT0;
                        data.d_right_rear(before_inds,2)=...
                            ids(i);
                    end
                    if start_ind ~= 1 && ...
                            data.d_right_front(start_ind-1,2) == ids(i)
                        savedAlong = true;
                        
                        data.d_right_front(before_inds,1)=...
                            beforeT0;
                        data.d_right_front(before_inds,2)=...
                            ids(i);
                        % Then we overwrite the rear right
                        data.d_right_rear(after_inds,1)=...
                            afterT0;
                        data.d_right_rear(after_inds,2)=...
                            ids(i);
                    end
                    
                    % Check the rear vehicles
                    if end_ind ~= length(bool_with_other) && ...
                            data.d_right_rear(end_ind+1,2) == ids(i)
                        savedAlong = true;
                        % Overwrite the disatances before T0 and after T0 on
                        % the right side
                        % First we overwrite the front left
                        data.d_right_front(before_inds,1)=...
                            beforeT0;
                        data.d_right_front(before_inds,2)=...
                            ids(i);
                        % Then we overwrite the rear left
                        data.d_right_rear(after_inds,1)=...
                            afterT0;
                        data.d_right_rear(after_inds,2)=...
                            ids(i);
                    end
                    if start_ind ~= 1 && ...
                            data.d_right_rear(start_ind-1,2) == ids(i)
                        savedAlong = true;
                        
                        % If the other car is overtaking from the right
                        % first, overwrite the rear right
                        data.d_right_rear(before_inds,1)=...
                            beforeT0;
                        data.d_right_rear(before_inds,2)=...
                            ids(i);
                        % then overwrite the front right
                        data.d_right_front(after_inds,1)=...
                            afterT0;
                        data.d_right_front(after_inds,2)=...
                            ids(i);
                    end
                    
                    
                    if ~savedAlong
                        data = false;
                        return
                    end
                end
                
            end
            
        end
        % Check whether any distances are larger than the predefined max
        d(d(:,1) > max_dist, 1) = max_dist;
    end
    % Save the data in the data struct
    switch position{:}
        case 'precedingId'
            data.d_front = d;
        case 'followingId'
            data.d_rear = d;
        case 'leftPrecedingId'
            data.d_left_front = d;
        case 'rightPrecedingId'
            data.d_right_front = d;
        case'leftFollowingId'
            data.d_left_rear = d;
        case 'rightFollowingId'
            data.d_right_rear = d;
        case 'leftAlongsideId'
            data.d_left_along = d;
        case 'rightAlongsideId'
            data.d_right_along = d;
    end
end
% Now, we want to check if the currentCar is in the most left or most
% right lane for this highway.  In this case, we want to set the
% distances to the left and to the right equal to zero, respectively.
% This is equivalent to a vehicle constantly driving next to the
% currentCar.
default_edge_lane = zeros(size(currentCar,1),2);
if any(unique(currentCar.laneId) == right_lanes)
    data.d_right_front = default_edge_lane;
    data.d_right_rear = default_edge_lane;
    data.d_right_along = default_edge_lane;
end

if any(unique(currentCar.laneId) == left_lanes)
    data.d_left_front = default_edge_lane;
    data.d_left_rear = default_edge_lane;
    data.d_left_along = default_edge_lane;
end

% place
% test = 1;