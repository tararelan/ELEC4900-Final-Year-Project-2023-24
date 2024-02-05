dataTable = readtable('Youngs.xlsx');
data = dataTable.Youngs;

k = 2;
distance = 'sqeuclidean';
maxIter = 1000;

[idx, centroids] = kmeans(data, k, 'Start', 'plus', 'Distance', distance, 'MaxIter', maxIter);

output = [transpose(1:length(data)), data, idx];

scatter(1:length(data), data, 'filled');
hold on;

cluster1 = find(idx == 1);  % Healthy
cluster2 = find(idx == 2);  % Unhealthy

%{
scatter(cluster1, data(cluster1), 'MarkerFaceColor', 'red'); % Assign red to Healthy cells
scatter(cluster2, data(cluster2), 'MarkerFaceColor', 'blue'); % Assign blue to Unhealthy cells
%}

xlabel('Index');
ylabel('Young''s Modulus');
title('Clustering of Healthy and Unhealthy Cells');
legend('', 'Healthy Cell', 'Unhealthy Cell');

grid on;
hold off;