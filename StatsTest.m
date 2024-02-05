data = xlsread('Youngs.xlsx', 'Stats');

group1 = data(~isnan(data(2:end, 1)), 1);
group2 = data(~isnan(data(2:end, 2)), 2);

[h, p, ci, stats] = ttest2(group1, group2);

disp('t-statistic: ', stats.tstat);
disp('p-value: ', p);
disp('95%% Confidence Interval: ', ci(1), ci(2));