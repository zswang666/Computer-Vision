% Starter code prepared by James Hays
% This function should return negative training examples (non-faces) from
% any images in 'non_face_scn_path'. Images should be converted to
% grayscale, because the positive training data is only available in
% grayscale. For best performance, you should sample random negative
% examples at multiple scales.

function [features_neg, neg_examples] = get_random_negative_features(non_face_scn_path, feature_params, num_samples)
% 'non_face_scn_path' is a string. This directory contains many images
%   which have no faces in them.
% 'feature_params' is a struct, with fields
%   feature_params.template_size (probably 36), the number of pixels
%      spanned by each train / test template and
%   feature_params.hog_cell_size (default 6), the number of pixels in each
%      HoG cell. template size should be evenly divisible by hog_cell_size.
%      Smaller HoG cell sizes tend to work better, but they make things
%      slower because the feature dimensionality increases and more
%      importantly the step size of the classifier decreases at test time.
% 'num_samples' is the number of random negatives to be mined, it's not
%   important for the function to find exactly 'num_samples' non-face
%   features, e.g. you might try to sample some number from each image, but
%   some images might be too small to find enough.

% 'features_neg' is N by D matrix where N is the number of non-faces and D
% is the template dimensionality, which would be
%   (feature_params.template_size / feature_params.hog_cell_size)^2 * 31
% if you're using the default vl_hog parameters

% Useful functions:
% vl_hog, HOG = VL_HOG(IM, CELLSIZE)
%  http://www.vlfeat.org/matlab/vl_hog.html  (API)
%  http://www.vlfeat.org/overview/hog.html   (Tutorial)
% rgb2gray

image_files = dir( fullfile( non_face_scn_path, '*.jpg' ));
num_images = length(image_files);  
level = 3; % scale_rate^0, scale_rate^1, scale_rate^2
scale_rate = 0.7;

% random sample
rand_idx = randi([1,num_images],1,num_samples);

neg_examples = cell(num_samples,1);

textprogressbar('Obtaining negative features: ');
features_neg = zeros(num_samples*level, (feature_params.template_size / feature_params.hog_cell_size)^2 * 31);
for i=1:num_samples,
    % read random sampled image
    img = imread([non_face_scn_path, '/', image_files(rand_idx(i)).name]);
    % convert to grayscale since trainset is in grayscale
    if(size(img,3) > 1),
        gray = rgb2gray(img);
    end
    
    % multi-scale
    for l=1:level,
        % downsample image according to current level
        gray_downsampled = imresize(gray, scale_rate^(l-1));
        % make sure size of downsampled images are larger than template_size
        if all(size(gray_downsampled)>=[feature_params.template_size,feature_params.template_size]),
            % random crop image and preprocessing
            cropped_gray = random_crop(gray_downsampled, feature_params.template_size);
            cropped_gray = random_aug(cropped_gray);
            % save
            neg_examples{(i-1)*level+l} = cropped_gray;
            % extract HOG from cropped image
            cropped_gray = im2single(cropped_gray);
            hog = vl_hog(single(cropped_gray), feature_params.hog_cell_size);
            % append to feature of negatives
            features_neg((i-1)*level+l,:) = hog(:).';
        end    
    end
    % visualize progress
    textprogressbar(i/num_samples*100);
end
textprogressbar(' done!');

end

function out = random_crop(img, crop_size)
    sz = size(img);
    xrange = [1, sz(2)-crop_size+1];
    yrange = [1, sz(1)-crop_size+1];
    xmin = randi(xrange);
    ymin = randi(yrange);
    out = imcrop(img,  [xmin, ymin, crop_size-1, crop_size-1]);
end

function out = random_aug(img)
    dice = randi([0,1],1,1);
    if dice,
        out = flip(img,2);
    else
        out = img;
    end
%     out = histeq(out);
end
