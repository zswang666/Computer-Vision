function [w, b] = svm_classify(x, y)
% check arguments
N = size(x,1);
assert(N==length(y));

% SVM parameters
lambda = 0.001;
maxIter = 1E5;
SVMeps = 1E-5;

% make x column-as-feature
x = x.';
% shuffle (x,y) pairs
perm = randperm(N);
x = x(:,perm);
y = y(perm);

% training
[w, b] = vl_svmtrain(x, y, lambda, ...
                   'MaxNumIterations',maxIter, ...
                   'Epsilon',SVMeps);

end