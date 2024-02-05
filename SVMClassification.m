dataTable = readtable('Youngs.xlsx');
X = dataTable.Youngs;
y = dataTable.Cluster;

SVMModel = fitcsvm(X,y,'Standardize',true,'KernelFunction','RBF',...
    'KernelScale','auto');
CVSVMModel = crossval(SVMModel);
classLoss = kfoldLoss(CVSVMModel);

classOrder = SVMModel.ClassNames;
sv = SVMModel.SupportVectors;

figure
gscatter(X, y)
hold on
plot(abs(sv(:,1)),'ko')
hold off