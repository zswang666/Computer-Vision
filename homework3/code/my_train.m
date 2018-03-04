%% prequisite
clear all; % to clear persistent variable in textprogressbar
addpath('../../textprogressbar');
run('../../vlfeat/toolbox/vl_setup');
addpath('../../libsvm-3.21/matlab');

data_path = '../data/'; %change if you want to work with a network copy

categories = {'Kitchen', 'Store', 'Bedroom', 'LivingRoom', 'Office', ...
       'Industrial', 'Suburb', 'InsideCity', 'TallBuilding', 'Street', ...
       'Highway', 'OpenCountry', 'Coast', 'Mountain', 'Forest'};
   
%This list of shortened category names is used later for visualization.
abbr_categories = {'Kit', 'Sto', 'Bed', 'Liv', 'Off', 'Ind', 'Sub', ...
    'Cty', 'Bld', 'St', 'HW', 'OC', 'Cst', 'Mnt', 'For'};
    
num_train_per_cat = 100; 

fprintf('Getting paths and labels for all train and test data\n')
[train_image_paths, test_image_paths, train_labels, test_labels] = ...
    get_image_paths(data_path, categories, num_train_per_cat);

%% training
% load model/bags_of_sifts_1000
load model/sp_sifts_400
% load model/fisher_vectors_ngmm_70
% load model/phow_fisher_vectors_ngmm_30

% CLASSIFIER = 'nearest neighbor';
% CLASSIFIER = 'support vector machine'; % vl_feat SVM, only support linear kernel 
CLASSIFIER = 'kernel svm'; % libsvm SVM, support linear/rbf/polynomial kernel
% CLASSIFIER = 'pyramid kernel svm';
% CLASSIFIER = 'placeholder';

fprintf('Using %s classifier to predict test set categories\n', CLASSIFIER)

switch lower(CLASSIFIER)    
    case 'nearest neighbor'
        predicted_categories = nearest_neighbor_classify(train_image_feats, train_labels, test_image_feats);
        
    case 'support vector machine'
        predicted_categories = svm_classify(train_image_feats, train_labels, test_image_feats);

    case 'kernel svm'
        svm_conf = '-q -t 0 -e 1e-5 -c 0.05'; % linear kernel
%         svm_conf = '-q -t 2 -g 0.01 -e 1e-5 -c 0.01'; % rbf kernel, sigma --> -g
%         svm_conf = '-q -t 1 -d 3 -e 1e-5 -c 0.01'; % polynomial kernel, degree --> -d
        predicted_categories = kernel_svm_classify(train_image_feats, train_labels, test_image_feats, svm_conf);
        
    case 'pyramid kernel svm'
        predicted_categories = PMkernel_svm_classify(train_image_feats, train_labels, test_image_feats);
        
    case 'placeholder'
        random_permutation = randperm(length(test_labels));
        predicted_categories = test_labels(random_permutation); 
        
    otherwise
        error('Unknown classifier type')
end

%% evaluation
create_results_webpage( train_image_paths, ...
                        test_image_paths, ...
                        train_labels, ...
                        test_labels, ...
                        categories, ...
                        abbr_categories, ...
                        predicted_categories)
