function vocab = build_fisher_vocabulary( image_paths, n_gmm )
% The inputs are images, a N x 1 cell array of image paths and the size of 
% the vocabulary.

% The output 'vocab' should be vocab_size x 128. Each row is a cluster
% centroid / visual word.

N = length(image_paths);
M = 500;
dSIFT_step = 10;

% get collection of SIFT discriptors
textprogressbar('building fisher vocabulary: ');
all_SIFT = [];
rand_idx = randi([1,N],1,M); % random sample M images
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

% form generative model
[means,covariance,priors] = vl_gmm(single(all_SIFT),n_gmm);
vocab = {means,covariance,priors};

textprogressbar(100);
textprogressbar(' done!');

end