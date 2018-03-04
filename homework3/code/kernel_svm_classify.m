function predicted_categories = kernel_svm_classify(train_image_feats, train_labels, test_image_feats, svm_conf)
% train_image_feats is an N x d matrix, where d is the dimensionality of the
%  feature representation.
% train_labels is an N x 1 cell array, where each entry is a string
%  indicating the ground truth category for each training image.
% test_image_feats is an M x d matrix, where d is the dimensionality of the
%  feature representation. You can assume M = N unless you've modified the
%  starter code.
% predicted_categories is an M x 1 cell array, where each entry is a string
%  indicating the predicted category for each test image.

categories = unique(train_labels); 
num_categories = length(categories);

N = size(train_image_feats,1);
M = size(test_image_feats,1);

% convert from string labels to numerical multiclass labels
labels = zeros(N,1);
for i=1:num_categories,
    labels(strcmp(train_labels,categories(i))) = i;
end    
% SVM parameters
if ~exist('svm_conf','var'),
    svm_conf = '-t 0 -e 1e-5 -c 0.01';
end

% disarrange training samples
perm = randperm(N);
train_image_feats = train_image_feats(perm,:);
labels = labels(perm);
% train num_categories binary classifiers
fprintf('start kernel svm training...\n');
model = svmtrain(labels, train_image_feats, svm_conf);
% prediction
test_init_labels = randi([1,num_categories],M,1);
fprintf('start predicting...\n');
pred = svmpredict(test_init_labels,test_image_feats,model);

% convert to string labels
predicted_categories = cell(M,1);
for i=1:M,
    predicted_categories{i} = categories{pred(i)};
end

end