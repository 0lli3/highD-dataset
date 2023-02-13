function output = calculateCentre(input)

% Make sure that the input has the correct dimension
if size(input,2) == 4
    % We assume that the first two columns of the input are the (x,y)
    % coordinates of the vehicle, and the second two are the height/width
    % of the vehicle.  Since the (x,y) coordinate is in the top left corner
    % of the bounding box, we need to add half the width and height to
    % caclulate the center of the vehicle.
    output = input(:,1:2) + input(:,3:4)./2;
end


end