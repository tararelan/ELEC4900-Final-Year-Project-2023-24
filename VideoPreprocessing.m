filename = "20231116 5ulhr  0.5W b_2023-11-16T20-32-57.004";
extension = ".avi";
videoFile = "C:\Users\tararelan\OneDrive - HKUST Connect\FYP\Videos\2023_11_16\" + filename + extension;
outputVideoFile = "C:\Users\tararelan\OneDrive - HKUST Connect\FYP\Videos\2023_11_16\Processed Video\" + filename + "_processed.mp4";

videoReader = VideoReader(videoFile);

background = readFrame(videoReader);
background = rgb2gray(background);

videoWriter = VideoWriter(outputVideoFile, 'MPEG-4');
open(videoWriter);

tic;

backgroundUpdateRate = 1;
backgroundSmoothingFactor = 1;
gaussianFilterStd = 1;
medianFilterSize = [5 5];

while hasFrame(videoReader)
    frame = readFrame(videoReader);
    grayFrame = rgb2gray(frame);
    normalizedFrame = imadjust(grayFrame);
    smoothedFrame = imgaussfilt(normalizedFrame, gaussianFilterStd);
    
    filteredFrame = medfilt2(smoothedFrame, medianFilterSize);
    
    foregroundMask = imbinarize(filteredFrame, 'adaptive', 'Sensitivity', 1);

    enhancedFrame = adapthisteq(filteredFrame);
    preprocessedFrame = double(enhancedFrame) .* double(foregroundMask);
    preprocessedFrame = preprocessedFrame / max(preprocessedFrame(:));

    background = backgroundSmoothingFactor * double(background) + (1 - backgroundSmoothingFactor) * double(grayFrame);

    if rand() < backgroundUpdateRate
        background = double(grayFrame);
    end

    writeVideo(videoWriter, preprocessedFrame);
end

elapsedTime = toc;

close(videoWriter);
preprocessedVideo = outputVideoFile;