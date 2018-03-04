function predicted_categories = PMkernel_svm_classify(train_image_feats, train_labels, test_image_feats, svm_conf)
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
% precomputed kernel function
vocab_size = 400;
L = 2; % 3-level
kernel_multiplier = zeros(1,L+1);
kernel_multiplier(1) = 1/(2^L);
for i=2:L+1,
    kernel_multiplier(i) = 1/(2^(L-i+1));
end
    function precompued_K = PMkernel_matrix(data1,data2)
        N1 = size(data1,1); N2 = size(data2,1);
        precompued_K = zeros(N1,N2);
        parfor i_in=1:N1,
            if mod(i_in,50)==0, % debug
                disp(i_in)
            end
            for j_in=1:N2,
                x1 = data1(i_in,:);
                x2 = data2(j_in,:);
                I = zeros(L+1,size(x1,1));
                r_start = 1;
                for l=1:L+1,
                    r_end = r_start + 2^(2*l-2)-1;
                    x1_l = x1((r_start-1)*vocab_size+1:r_end*vocab_size); 
                    x2_l = x2((r_start-1)*vocab_size+1:r_end*vocab_size);
                    tmp = min([x1_l;x2_l],[],1); 
%                     tmp = reshape(tmp,vocab_size,2^(2*l-2)); % columns as hists
                    I(l) = sum(tmp,2);
                    r_start = r_end;
                end
                precompued_K(i_in,j_in) = kernel_multiplier*I;
            end
        end
    end
% disarrange training samples
perm = randperm(N);
train_image_feats = train_image_feats(perm,:);
labels = labels(perm);
% compute kernel matrix
fprintf('compute precomputed kernel matrix for training...');
train_precomputed_K = PMkernel_matrix(train_image_feats,train_image_feats);
train_precomputed_K = [(1:N)', train_precomputed_K];
% train num_categories binary classifiers
fprintf('start svm training...');
model = svmtrain(labels, train_precomputed_K, svm_conf);
% prediction
fprintf('compute precomputed kernel matrix for testing...');
test_precomputed_K = PMkernel_matrix(test_image_feats,train_image_feats);
test_precomputed_K = [(1:M)', test_precomputed_K];
test_init_labels = randi([1,num_categories],M,1);
fprintf('start predicting...');
pred = svmpredict(test_init_labels,test_precomputed_K,model);

% convert to string labels
predicted_categories = cell(M,1);
for i=1:M,
    predicted_categories{i} = categories{pred(i)};
end

end


%     function out = PMkernel(x1,x2)
%         I = zeros(L+1,size(x1,1));
%         r_start = 1;
%         for l=1:L+1,
%             r_end = r_start + 2^(2*l-2)-1;
%             x1_l = x1((r_start-1)*vocab_size+1:r_end*vocab_size); 
%             x2_l = x2((r_start-1)*vocab_size+1:r_end*vocab_size);
%             tmp = min(x1_l,x2_l); 
%             tmp = reshape(x1_l,vocab_size,2^(2*l-2)); % columns as hists
%             I(l) = sum(tmp,2);
%             r_start = r_end;
%         end
%         out = kernel_multiplier*I; % size=(1,#_of_samples)
%     end