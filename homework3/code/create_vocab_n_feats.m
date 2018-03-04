% to create different vocabulary size of vocabulary and features

clear all; % to clear persistent variable in textprogressbar
addpath('../../textprogressbar');
run('../../vlfeat/toolbox/vl_setup')

data_path = '../data/'; %change if you want to work with a network copy

%This is the list of categories / directories to use. The categories are
%somewhat sorted by similarity so that the confusion matrix looks more
%structured (indoor and then urban and then rural).
categories = {'Kitchen', 'Store', 'Bedroom', 'LivingRoom', 'Office', ...
       'Industrial', 'Suburb', 'InsideCity', 'TallBuilding', 'Street', ...
       'Highway', 'OpenCountry', 'Coast', 'Mountain', 'Forest'};
   
%This list of shortened category names is used later for visualization.
abbr_categories = {'Kit', 'Sto', 'Bed', 'Liv', 'Off', 'Ind', 'Sub', ...
    'Cty', 'Bld', 'St', 'HW', 'OC', 'Cst', 'Mnt', 'For'};
    
%number of training examples per category to use. Max is 100. For
%simplicity, we assume this is the number of test cases per category, as
%well.
num_train_per_cat = 100; 

%This function returns cell arrays containing the file path for each train
%and test image, as well as cell arrays with the label of each train and
%test image. By default all four of these arrays will be 1500x1 where each
%entry is a char array (or string).
fprintf('Getting paths and labels for all train and test data\n')
[train_image_paths, test_image_paths, train_labels, test_labels] = ...
    get_image_paths(data_path, categories, num_train_per_cat);
%   train_image_paths  1500x1   cell      
%   test_image_paths   1500x1   cell           
%   train_labels       1500x1   cell         
%   test_labels        1500x1   cell          

%% fisher vectors
% gmm_pool = [10 30 50 70];
% num_training_samples = 500;
% for n_gmm = gmm_pool,
%     fprintf(['# gmm = ',num2str(n_gmm),':\n']);
%     % build vocabulary
%     fprintf('build vocabulary, ');
%     dSIFT_step = 10;
% 	vocab = build_fisher_vocabulary(train_image_paths, n_gmm);
%     file_name = ['model/fisher_vocab_ngmm_',num2str(n_gmm),'.mat'];
% 	save(file_name, 'vocab', 'n_gmm', 'num_training_samples', 'dSIFT_step');
%     % extract features
%     vocab_path = file_name;
%     fprintf('train_image_feats, ');
%     dSIFT_step = 5;
%     tic
%     train_image_feats = get_fisher_vector(train_image_paths,vocab_path);
%     toc
%     fprintf('test_image_feats, ');
%     tic
%     test_image_feats  = get_fisher_vector(test_image_paths,vocab_path);
%     toc
%     file_name = ['model/fisher_vectors_ngmm_',num2str(n_gmm),'.mat'];
%     save(file_name,'train_image_feats','test_image_feats','dSIFT_step');
% end

%% PHOW fisher
% gmm_pool = [10 30 50 70];
% num_training_samples = 500;
% for n_gmm = gmm_pool,
%     fprintf(['# gmm = ',num2str(n_gmm),':\n']);
%     % build vocabulary
%     fprintf('build vocabulary, ');
%     dSIFT_step = 10;
% 	vocab = build_phow_fisher_vocabulary(train_image_paths, n_gmm);
%     file_name = ['model/phow_fisher_vocab_ngmm_',num2str(n_gmm),'.mat'];
% 	save(file_name, 'vocab', 'n_gmm', 'num_training_samples', 'dSIFT_step');
%     % extract features
%     vocab_path = file_name;
%     fprintf('train_image_feats, ');
%     dSIFT_step = 5;
%     tic
%     train_image_feats = get_phow_fisher_vector(train_image_paths,vocab_path);
%     toc
%     fprintf('test_image_feats, ');
%     tic
%     test_image_feats  = get_phow_fisher_vector(test_image_paths,vocab_path);
%     toc
%     file_name = ['model/phow_fisher_vectors_ngmm_',num2str(n_gmm),'.mat'];
%     save(file_name,'train_image_feats','test_image_feats','dSIFT_step');
% end

%% SIFTs vocabulary
% vocab_size_pool = [20 100 400 1000];
% num_training_samples = 500;
% for vocab_size = vocab_size_pool,
%     fprintf(['# vocab_size = ',num2str(vocab_size),':\n']);
%     % build vocabulary
%     fprintf('build vocabulary, ');
%     dSIFT_step = 10;
% 	vocab = build_vocabulary(train_image_paths, vocab_size);
%     file_name = ['model/vocab_',num2str(vocab_size),'.mat'];
% 	save(file_name, 'vocab', 'vocab_size', 'num_training_samples', 'dSIFT_step');
% end
% 
%% bag of SIFTs
vocab_size_pool = [20 100 400 1000];
num_training_samples = 500;
for vocab_size = vocab_size_pool,
    fprintf(['# vocab_size = ',num2str(vocab_size),':\n']);
    vocab_path = ['model/vocab_',num2str(vocab_size),'.mat'];
    % extract features
    fprintf('train_image_feats, ');
    dSIFT_step = 5;
    tic
    train_image_feats = get_bags_of_sifts(train_image_paths,vocab_path);
    toc
    fprintf('test_image_feats, ');
    tic
    test_image_feats  = get_bags_of_sifts(test_image_paths,vocab_path);
    toc
    file_name = ['model/bags_of_sifts_',num2str(vocab_size),'.mat'];
    save(file_name,'train_image_feats','test_image_feats','dSIFT_step');
end

%% spatial pyramid SIFTs
% vocab_size_pool = [20 100 400 1000];
% num_training_samples = 500;
% for vocab_size = vocab_size_pool,
%     fprintf(['# vocab_size = ',num2str(vocab_size),':\n']);
%     vocab_path = ['model/vocab_',num2str(vocab_size),'.mat'];
%     % extract features
%     fprintf('train_image_feats, ');
%     dSIFT_step = 5;
%     tic
%     train_image_feats = get_sp_sifts(train_image_paths,vocab_path);
%     toc
%     fprintf('test_image_feats, ');
%     tic
%     test_image_feats  = get_sp_sifts(test_image_paths,vocab_path);
%     toc
%     file_name = ['model/sp_sifts_',num2str(vocab_size),'.mat'];
%     save(file_name,'train_image_feats','test_image_feats','dSIFT_step');
% end