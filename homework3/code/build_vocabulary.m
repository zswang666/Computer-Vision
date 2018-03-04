% Starter code prepared by James Hays

%This function will sample SIFT descriptors from the training images,
%cluster them with kmeans, and then return the cluster centers.

function vocab = build_vocabulary( image_paths, vocab_size )
% The inputs are images, a N x 1 cell array of image paths and the size of 
% the vocabulary.

% The output 'vocab' should be vocab_size x 128. Each row is a cluster
% centroid / visual word.

N = length(image_paths);
M = 500;
dSIFT_step = 10;

% get collection of SIFT discriptors
textprogressbar('building vocabulary: ');
rand_idx = randi([1,N],1,M); % random sample M images
all_SIFT = [];
for i=1:M,
	% read an image
	img = single(imread(image_paths{rand_idx(i)}));
	% obtain dense SIFT of the image (loc unused now)
	[~,SIFT_features] = vl_dsift(img,'step',dSIFT_step);
	% append SIFTs
    all_SIFT = [all_SIFT, SIFT_features];
    % visualize progress
    textprogressbar(i/M*80);
end

% vocab is a matrix with each column as a feature
[vocab,~] = vl_kmeans(single(all_SIFT),vocab_size);

textprogressbar(100);
textprogressbar(' done!');

%{
Useful functions:
[locations, SIFT_features] = vl_dsift(img) 
 http://www.vlfeat.org/matlab/vl_dsift.html
 locations is a 2 x n list list of locations, which can be thrown away here
  (but possibly used for extra credit in get_bags_of_sifts if you're making
  a "spatial pyramid").
 SIFT_features is a 128 x N matrix of SIFT features
  note: there are step, bin size, and smoothing parameters you can
  manipulate for vl_dsift(). We recommend debugging with the 'fast'
  parameter. This approximate version of SIFT is about 20 times faster to
  compute. Also, be sure not to use the default value of step size. It will
  be very slow and you'll see relatively little performance gain from
  extremely dense sampling. You are welcome to use your own SIFT feature
  code! It will probably be slower, though.

[centers, assignments] = vl_kmeans(X, K)
 http://www.vlfeat.org/matlab/vl_kmeans.html
  X is a d x M matrix of sampled SIFT features, where M is the number of
   features sampled. M should be pretty large! Make sure matrix is of type
   single to be safe. E.g. single(matrix).
  K is the number of clusters desired (vocab_size)
  centers is a d x K matrix of cluster centroids. This is your vocabulary.
   You can disregard 'assignments'.

  Matlab has a build in kmeans function, see 'help kmeans', but it is
  slower.
%}

% Load images from the training set. To save computation time, you don't
% necessarily need to sample from all images, although it would be better
% to do so. You can randomly sample the descriptors from each image to save
% memory and speed up the clustering. Or you can simply call vl_dsift with
% a large step size here, but a smaller step size in make_hist.m. 

% For each loaded image, get some SIFT features. You don't have to get as
% many SIFT features as you will in get_bags_of_sift.m, because you're only
% trying to get a representative sample here.

% Once you have tens of thousands of SIFT features from many training
% images, cluster them with kmeans. The resulting centroids are now your
% visual word vocabulary.

end

% % get number of SIFTs of one image
% [~,SIFT_features] = vl_dsift(single(imread(image_paths{1})),'size',binSize);
% num_SIFT_per_img = size(SIFT_features,2);
% all_SIFT = zeros(128,num_SIFT_per_img*M); % a column is a feature

% now_range = (i-1)*num_SIFT_per_img+1:i*num_SIFT_per_img;
% all_SIFT(:,now_range) = SIFT_features;

% all_SIFT = [];
% all_SIFT = [all_SIFT, SIFT_features];

