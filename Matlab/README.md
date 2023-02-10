## Extract Lane Changes
We extend the original highD Matlab tools to further extract the lane changes with additional features not found in the `.csv` files. To extract the lane changes run `bin/collectLaneChanges.m`. The extracted lane changes can be prepared for machine learning applications using the `bin/saveLaneChanges.m` file.

The remaining tools provided by the highD team have been left untouched.

### How to extract lane changes
1) Copy the csv files into the `/data` directory.
2) Run `bin/collectLaneChanges.m` and `bin/collectLocations.m`.
3) (Optional) Update `bin/saveLaneChanges.m` with the extracted lane changes file names and run it.

## highD Matlab tools
These tools allow you to read-in the highD csv files and visualize them in an interactive 
plot. Through modularity, one can use the i/o functions directly for individual applications.

```
 |- bin
    |- collectLaneChanges.m
    |- collectLocations.m
    |- saveLaneChanges.m
    |- startVisualization.m
 |- data
 |- results
 |- utils
    |- calculateCentre.m
    |- getDistance.m
    |- getLaneChangeFrame.m
    |- getLaneDistances.m
    |- plotHighway.m
    |- plotTracks.m
    |- plotTracksOnImage.m
    |- readInLaneChangeCsv.m
    |- readInTracksCsv.m
    |- readInVideoCsv.m
 |- visualization
    |- trackVisualization.fig
    |- trackVisualization.m
 |- initialize.m
```

## Quickstart
1) Copy the csv files into the data directory
2) Run initialize.m
3) (Optional) Modify the videoName variable in bin/startVisualization.m
4) Run bin/startVisualization.m

## Method descriptions

### initialize.m
This script adds the folders to the working directory.

### bin

#### bin/collectLaneChanges.m
Main script to extract the lane changes from the highD dataset.

#### bin/collectLocations.m
Script to extract the filming locations from the highD dataset.

#### bin/saveLaneChanges.m
Script to prepare the extracted lane changes for a machine learning application.

#### bin/startVisualization.m
Main visualization script.

### utils

#### utils/calculateCentre.m
This function calculates the centre of the vehicle at a particular frame.

#### utils/getDistance.m
This function calculates the distance from the centre of the currently observed vehicle to the centre of the surrounding vehicles.

#### utils/getLaneChangeFrame.m
This function calculates the frame where the centre of the currently observed vechile crosses the lane marking.

#### utils/getLaneDistances.m
This function calculates the distance from the centre of a vehicle to the closet lane markings.

#### utils/readInLaneChangeCsv.m
This script extracts the lane changes from the tracks csv files from the highD dataset. It is adapted from the `utils/readInTracksCsv.m` file.

#### utils/readInTracksCsv.m
This script extract tracks from the tracks csv file from highD. The structure that is extracted is clear 
and easy to use. Each track (a tracked vehicle) is an own struct containing all static and dynamic information 
for each frame that the vehicle is detected in. This script takes the dynamic and static tracks csv file and combines 
the information into one struct.

#### utils/readInVideoCsv.m
This script reads-in the video meta data from the highD csv file. 

#### utils/plotHighway.m
This script creates the highway from the lane description. The lanes are plotted into the "params.ax" axis. 

#### utils/plotTracks.m
This script plots the vehicles of a specific frame on virtual lanes. The used axis is the one passed with "params.ax".

#### utils/plotTracksOnImage.m
This script plots the vehicles of a specific frame on a background image. The used axis is the one passed with "params.ax".

### visualization

#### trackVisualization.m
This script is a complete program that creates an user interface. The user interface allows switching between frames 
of the given highD data containing virtual vehicles. The virtual vehicles contain some information about their tracks, 
which can be shown by clicking the vehicle bounding box. 
