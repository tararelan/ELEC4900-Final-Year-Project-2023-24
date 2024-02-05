function [numCells, largestInd, dataBBox, tracks, lostTracks] = CellTracker()

    folder = "C:\Users\tararelan\OneDrive - HKUST Connect\FYP\Videos\2023_11_16\Processed Video\";
    filename = "20231116 5ulhr  0.5W b_2023-11-16T20-32-57.004_processed.mp4";

    input_file = folder + filename;

    obj = setupSystemObjects();
    tracks = initializeTracks();
    lostTracks = initializeTracks();
    nextId = 1;
    dataBBox = zeros(1, 4); % create bbox for data

    se90 = strel('line', 3, 90);
    se0 = strel('line', 3, 0);
    seD = strel('disk', 1);

    numCells = 0; % number of cells
    largestInd = 0; % largest index of reliable tracks


    % transform frames to videos
    outputVideo_mask = VideoWriter(fullfile('C:\Users\tararelan\OneDrive\Documents\MATLAB\ELEC4900\output video\', filename + ' output.avi'));

    % outputVideo.FrameRate = obj.reader.FrameRate;
    outputVideo_mask.FrameRate = obj.reader.FrameRate;

    % open(outputVideo);
    open(outputVideo_mask);

    framecount = 0;
    while hasFrame(obj.reader)
        
        frame = readFrame(obj.reader);
        framecount = framecount + 1;
        %frame = huidubianhuan(frame, 5, 4);
        [centroids, bboxes, mask] = detectObjects(frame);
        predictNewLocationsOfTracks();
        [assignments, unassignedTracks, unassignedDetections] = detectionToTrackAssignment();
        updateAssignedTracks();
        updateUnassignedTracks();
        deleteLostTracks();
        createNewTracks();
        trackSpeed();
        trackDiameter();
        
        displayTrackingResults();
        
    end

    function obj = setupSystemObjects()
        
        obj.reader = VideoReader(input_file);

        videoWidth = obj.reader.Width;
        videoHeight = obj.reader.Height;

        obj.maskPlayer = vision.VideoPlayer('Position', [740, 400, 700, 400]); % Can change
        obj.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]); % Can change
        
        obj.detector = vision.ForegroundDetector('NumGaussians', 3, ...
            'NumTrainingFrames', 200, 'MinimumBackgroundRatio', 0.5, ...
            'LearningRate', 0.0000001); % Can change NumTrainingFrames
        
        obj.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
            'AreaOutputPort', true, 'CentroidOutputPort', true, ...
            'MinimumBlobArea', 700, 'MaximumBlobArea', 5000, 'ExcludeBorderBlobs', true);
        % added MaximumBlobArea   Can increase MaxAxisLengthOutputPort, Min...,
        % ExcludeBorderBlobs
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

    function [centroids, bboxes, mask] = detectObjects(frame)
        mask = obj.detector.step(frame);
        
        mask = imdilate(mask, [se90 se0]);
        mask = imfill(mask, 'holes');
        mask = imerode(mask, seD);
        mask = imerode(mask, seD);
        % below are additional erosions
        mask = imerode(mask, seD);
        mask = imerode(mask, seD);
        
        [~, centroids, bboxes] = obj.blobAnalyser.step(mask); % where bbox is created
    end

    function predictNewLocationsOfTracks()
        for i = 1:length(tracks)
            bbox = tracks(i).bbox(end, :);
            
            predictedCentroid = predict(tracks(i).kalmanFilter);
            
            predictedCentroid = int32(predictedCentroid) - bbox(3:4) / 2;
            tracks(i).bbox = cat(1, tracks(i).bbox, [predictedCentroid, bbox(3:4)]);
        end
    end

    function [assignments, unassignedTracks, unassignedDetections] = detectionToTrackAssignment()
        
        nTracks = length(tracks);
        nDetections = size(centroids, 1);
        
        cost = zeros(nTracks, nDetections);
        for i = 1:nTracks
            cost(i, :) = distance(tracks(i).kalmanFilter, centroids);
        end
        
        % below is to be adjusted
        costOfNonAssignment = 10;
        [assignments, unassignedTracks, unassignedDetections] = assignDetectionsToTracks(cost, costOfNonAssignment);
    end

    function updateAssignedTracks()
        numAssignedTracks = size(assignments, 1);
        for i = 1:numAssignedTracks
            trackIdx = assignments(i, 1);
            detectionIdx = assignments(i, 2);
            centroid = centroids(detectionIdx, :);
            bbox = bboxes(detectionIdx, :);
            
            correct(tracks(trackIdx).kalmanFilter, centroid);
            
            tracks(trackIdx).bbox = cat(1, tracks(trackIdx).bbox(1:end-1, :), bbox);
            tracks(trackIdx).age = tracks(trackIdx).age + 1;
            tracks(trackIdx).totalVisibleCount = tracks(trackIdx).totalVisibleCount + 1;
            tracks(trackIdx).consecutiveInvisibleCount = 0;
            tracks(trackIdx).validFrame = [tracks(trackIdx).validFrame, 1];
        end
    end

    function updateUnassignedTracks()
        for i = 1:length(unassignedTracks)
            ind = unassignedTracks(i);
            tracks(ind).age = tracks(ind).age + 1;
            tracks(ind).consecutiveInvisibleCount = tracks(ind).consecutiveInvisibleCount + 1;
            tracks(ind).validFrame = [tracks(ind).validFrame, 0];
            %tracks(ind).bbox = cat(1, tracks(ind).bbox, [1, 1, 1, 1]);
        end
    end

    function deleteLostTracks()
        if isempty(tracks)
            return;
        end
        
        invisibleForTooLong = 20;
        ageThreshold = 8;
        
        ages = [tracks(:).age];
        totalVisibleCounts = [tracks(:).totalVisibleCount];
        visibility = totalVisibleCounts ./ ages;
        
        lostInds = (ages < ageThreshold & visibility < 0.1) | [tracks(:).consecutiveInvisibleCount] >= invisibleForTooLong;
        
        lostTrackThisRound = tracks(lostInds);
        for i = 1:length(lostTrackThisRound)
            lostTracks(end+1) = lostTrackThisRound(i);
        end
        tracks = tracks(~lostInds);
    end

    function createNewTracks()
        centroids = centroids(unassignedDetections, :);
        bboxes = bboxes(unassignedDetections, :);
        
        for i = 1:size(centroids, 1)
            centroid = centroids(i, :);
            bbox = bboxes(i, :);
            
            kalmanFilter = configureKalmanFilter('ConstantAcceleration', centroid, [200, 50, 50], [100, 25, 50], 100);
            
            newTrack = struct(...
                'id', nextId, ...
                'bbox', bbox, ...
                'kalmanFilter', kalmanFilter, ...
                'age', 1, ...
                'totalVisibleCount', 1, ...
                'consecutiveInvisibleCount', 0, ...
                'startFrame', framecount, ...
                'validFrame', uint8(1), ...
                'speed', 0, ...
                'diameterX', [], ...
                'diameterY', [], ...
                'maxChangeIdX', 0, ...
                'maxChangeIdY', 0, ...
                'firstZeroIdX', 0, ...
                'firstZeroIdY', 0, ...
                'Youngs', 0);
            
            tracks(end + 1) = newTrack;
            nextId = nextId + 1;
        end
    end
    
    function trackSpeed()
        speeds = [];
        for i = 1:length(tracks)
            bbox = tracks(i).bbox;
            numFrames = size(bbox, 1);
            if numFrames >= 2
                distances = sqrt(sum(diff(bbox(:, 1:2)).^2, 2));
                timeGaps = double(diff(tracks(i).validFrame));
                speeds = distances ./ timeGaps;
                %{
                speeds = median(~isnan(speeds));
                tracks(i).speed = speeds(1);
                %}
            end
            speeds = rmmissing(speeds, 2);
            tracks(i).speed = speeds;
        end
    end

    function trackDiameter()
        for i = 1:length(tracks)
            bbox = tracks(i).bbox;
            diametersX = bbox(:, 4);
            initialDiameterX = diametersX(1);
            changeInDiameterX = diametersX - initialDiameterX;
    
            [~, maxChangeIdX] = max(abs(changeInDiameterX));
            firstZeroIdsX = find(changeInDiameterX(maxChangeIdX + 1:end) == 0, 1) + maxChangeIdX;

            
            tracks(i).diameterX = [diametersX, changeInDiameterX];
            tracks(i).maxChangeIdX = maxChangeIdX;
    
            diametersY = bbox(:, 3);
            initialDiameterY = diametersY(1);
            changeInDiameterY = diametersY - initialDiameterY;
    
            [~, maxChangeIdY] = max(changeInDiameterY);
            firstZeroIdsY = find(changeInDiameterY(maxChangeIdY + 1:end) == 0, 1) + maxChangeIdY;
            
            tracks(i).diameterY = [diametersY, changeInDiameterY];
            tracks(i).maxChangeIdY = maxChangeIdY;
            tracks(i).firstZeroIdX = firstZeroIdsX;
            tracks(i).firstZeroIdY = firstZeroIdsY;
        end
    end

    function displayTrackingResults()
        
        frame = im2uint8(frame);
        mask = uint8(repmat(mask, [1, 1, 3])) .* 255;
        
        minVisibleCount = 8;
        if ~isempty(tracks)
            
            reliableTrackInds = [tracks(:).totalVisibleCount] > minVisibleCount;
            reliableTracks = tracks(reliableTrackInds);
            
            if ~isempty(reliableTracks)
                
                ids = int32([reliableTracks(:).id]);
                
                % below is for finding the number of cells
                idsT = ids';
                
                for i = 1:size(idsT)
                    if largestInd < idsT(i)
                        numCells = numCells + 1;
                        largestInd = idsT(i);
                    end
                end
                
                bboxes = [];
                for i = 1:size(idsT)
                    bboxes = cat(1, bboxes, reliableTracks(i).bbox(end, :));
                end
                
                % concatenate the bboxes to dataBBoxes below
                dataBBox = cat(1, dataBBox, bboxes);
                
                labels = cellstr(int2str(ids'));
                predictedTrackInds = [reliableTracks(:).consecutiveInvisibleCount] > 0;
                isPredicted = cell(size(labels));
                isPredicted(predictedTrackInds) = {' predicted'};
                labels = strcat(labels, isPredicted);
                
                frame = insertObjectAnnotation(frame, 'rectangle', bboxes, labels);
            end
        end
        
        obj.maskPlayer.step(mask);
        obj.videoPlayer.step(frame);
        
        % write the frames to output video
        % writeVideo(outputVideo, frame);
        writeVideo(outputVideo_mask, mask);
    end

    % finalize the output
    % remember to comment the output code while not needed
    % close(outputVideo);
    close(outputVideo_mask);
    function updated_image = huidubianhuan(image, C, X)
        image = im2double(image);
        updated_image = C*(image.^X);
    end

end