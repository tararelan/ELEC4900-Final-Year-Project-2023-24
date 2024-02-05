dataTable = readtable('Youngs.xlsx');
data = dataTable.Youngs;

zScores = zscore(data);

outlierThreshold = 3;

outlierIndices = find(abs(zScores) > outlierThreshold);
dataWithoutOutliers = data;
dataWithoutOutliers(outlierIndices) = [];
removedOutliers = data(outlierIndices);

figure;
subplot(2, 1, 1);
plot(data);
title('Original Data');
ylabel('Value');

subplot(2, 1, 2);
plot(dataWithoutOutliers);
title('Data without Outliers');
ylabel('Value');

disp('Removed Outliers: ', removedOutliers);