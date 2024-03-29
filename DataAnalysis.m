[number, index, bbox, tracks, lostTracks] = CellTracker();
close all;

allTracks = [lostTracks, tracks];
clusterDatas = initializeClusterDatas();
for i = 1:size(allTracks, 2)
    track = allTracks(i);
    centroidX = double(track.bbox(:, 1) + track.bbox(:, 3)/2);
    centroidY = double(track.bbox(:, 2) + track.bbox(:, 3)/2);
    centroid = [centroidX centroidY];
    
    if size(centroid, 1) < 3
        continue;
    end
    
    [idx, c, sumd] = kmeans(centroid, 3, 'Distance', 'cityblock');
    count = [sum(idx(:) == 1); sum(idx(:) == 2); sum(idx(:) == 3)];
    averageDistance = sumd./count;
    
    clusterData = struct( ...
        'id', track.id, ...
        'clusterCentroid', c, ...
        'averageDistance', averageDistance, ...
        'centroidStd', std(averageDistance), ...
        'maxDistance', max(averageDistance), ...
        'minDistance', min(averageDistance));
    
    clusterDatas(end+1) = clusterData;
    
end

trappedClusterDataInd = [clusterDatas(:).centroidStd] > 10 & [clusterDatas(:).maxDistance] < 90 ...
    & [clusterDatas(:).minDistance] > 1;
trappedClusterData = clusterDatas(trappedClusterDataInd);


potentialCentroid = [];
for i = 1:sum(trappedClusterDataInd)
    ind = [trappedClusterData(i).averageDistance] == min(trappedClusterData(i).averageDistance);
    a = trappedClusterData(i).clusterCentroid(ind, :);
    potentialCentroid = cat(1, potentialCentroid, a);
end

%{
figure(1);
scatter(potentialCentroid(:, 1), potentialCentroid(:, 2), 'filled'); xlabel('pixels(×0.15μm)');ylabel('pixels(×0.15μm)');
title('potential locations of focus');
hold;
%}
[idx1, C, sumd] = kmeans(potentialCentroid, 1, 'Distance', 'cityblock');
%{
scatter(C(:, 1), C(:, 2), 60 ,'red', 'filled');
xlabel('x'); ylabel('y');
label = dbscan(potentialCentroid, 10, 7);
gscatter(potentialCentroid(:, 1), potentialCentroid(:, 2), label);
BeamSpots = potentialCentroid(label == 1, :);
C = [sum(BeamSpots(:, 1))/size(BeamSpots, 1), sum(BeamSpots(:, 2))/size(BeamSpots, 1)];
%}

trappedCells = extractTrappedCells(C, allTracks, 2);

function clusterDatas = initializeClusterDatas()
    clusterDatas = struct( ...
        'id', {}, ...
        'clusterCentroid', {}, ...
        'averageDistance', {}, ...
        'centroidStd', {}, ...
        'maxDistance', {}, ...
        'minDistance', {});
end

function tracks = initializeTracks()
    tracks = struct(...
        'id', {}, ...
        'bbox', {}, ...
        'kalmanFilter', {}, ...
        'age', {}, ...
        'totalVisibleCount', {}, ...
        'consecutiveInvisibleCount', {}, ...
        'startFrame', {}, ...
        'validFrame', {}, ...
        'speed', {}, ...
        'diameterX', {}, ...
        'diameterY', {}, ...
        'maxChangeIdX', {}, ...
        'maxChangeIdY', {}, ...
        'firstZeroIdX', {}, ...
        'firstZeroIdY', {}, ...
        'Youngs', {});
end

function trappedCells = extractTrappedCells(c, allTracks, plotOption)
    % figure(2);
    tolerance = 6;
    minConnectArea = 4;
    trappedCells = initializeTracks();
    ncolor = 1;

    for i = 1:size(c, 1)
        for j = 1:size(allTracks, 2)
            track = allTracks(j);
            %track = allTracks([allTracks(:).id] == 92);
            centroidX = double(track.bbox(:, 1) + track.bbox(:, 3)/2);
            centroidY = double(track.bbox(:, 2) + track.bbox(:, 3)/2);
            xSatisfied = centroidX < c(i, 1) + tolerance & centroidX > c(i, 1) - tolerance;
            ySatisfied = centroidY < c(i, 2) + tolerance & centroidY > c(i, 2) - tolerance;
            satisfied = xSatisfied & ySatisfied;
            [L, n] = bwlabel(satisfied);
            for k = 1:n
                [row, col] = find(L == k);
                count = size(col, 1);
                
                if count >= minConnectArea
                    trappedCells(end+1) = track;
                    
                    if plotOption == 1
                        
                        subplot(3,1,1);
                        scatter(track.bbox(row, 3), track.bbox(row, 4), 'filled');hold on;
                        xlim([0, 100]); ylim([20, 100]); title('trapped cells size');
                        xlabel('width'); ylabel('height');
                        
                        subplot(3,1,2);
                        scatter(track.bbox(1:row(1), 3), track.bbox(1:row(1), 4), 'filled');hold on;
                        xlim([0, 100]); ylim([20, 100]); title('before trapped cell size');
                        xlabel('width'); ylabel('height');
                        
                        subplot(3,1,3);
                        scatter(track.bbox(row(end)+1:end, 3), track.bbox(row(end)+1:end, 4), 'filled');hold on;
                        xlim([0, 100]); ylim([20, 100]); title('after trapped cell size');
                        xlabel('width'); ylabel('height');
                        
                        
                    else
                        subplot(3,1,1);
                        scatter(mean(track.bbox(row, 3)), mean(track.bbox(row, 4)), 30, [ncolor/20, 1-ncolor/20, 1-ncolor/20],'filled');hold on;
                        xlim([0, 100]); ylim([20, 100]); title('trapped cells size');
                        xlabel('width'); ylabel('height');
                        
                        subplot(3,1,2);
                        scatter(mean(track.bbox(1:row(1), 3)), mean(track.bbox(1:row(1), 4)), 30, [ncolor/20, 1-ncolor/20, 1-ncolor/20], 'filled');hold on;
                        xlim([0, 100]); ylim([20, 100]); title('before trapped cell size');
                        xlabel('width'); ylabel('height');
                        
                        subplot(3,1,3);
                        scatter(mean(track.bbox(row(end)+1:end, 3)), mean(track.bbox(row(end)+1:end, 4)), 30, [ncolor/20, 1-ncolor/20, 1-ncolor/20], 'filled');hold on;
                        xlim([0, 100]); ylim([20, 100]); title('after trapped cell size');
                        xlabel('width'); ylabel('height');
                        
                    end
                    ncolor = ncolor + 1;
                    
                    break;
                end
                
            end
        end
    end
end