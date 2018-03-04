% Starter code prepared by James Hays
% This function should return all positive training examples (faces) from
% 36x36 images in 'train_path_pos'. Each face should be converted into a
% HoG template according to 'feature_params'. For improved performance, try
% mirroring or warping the positive training examples.

function features_pos = get_positive_features(train_path_pos, feature_params)
% 'train_path_pos' is a string. This directory contains 36x36 images of
%   faces
% 'feature_params' is a struct, with fields
%   feature_params.template_size (probably 36), the number of pixels
%      spanned by each train / test template and
%   feature_params.hog_cell_size (default 6), the number of pixels in each
%      HoG cell. template size should be evenly divisible by hog_cell_size.
%      Smaller HoG cell sizes tend to work better, but they make things
%      slower because the feature dimensionality increases and more
%      importantly the step size of the classifier decreases at test time.


% 'features_pos' is N by D matrix where N is the number of faces and D
% is the template dimensionality, which would be
%   (feature_params.template_size / feature_params.hog_cell_size)^2 * 31
% if you're using the default vl_hog parameters

% Useful functions:
% vl_hog, HOG = VL_HOG(IM, CELLSIZE)
%  http://www.vlfeat.org/matlab/vl_hog.html  (API)
%  http://www.vlfeat.org/overview/hog.html   (Tutorial)
% rgb2gray

image_files = dir( fullfile( train_path_pos, '*.jpg') ); %Caltech Faces stored as .jpg
num_images = length(image_files);

num_samples = num_images;

textprogressbar('Obtaining positive features: ');
features_pos = zeros(num_samples, (feature_params.template_size / feature_params.hog_cell_size)^2 * 31);
for i=1:num_samples,
    % read image and perform preprocessing
    img = imread([train_path_pos, '/', image_files(i).name]);
    img = random_aug(img);
    img = im2single(img);
    % extract HOG from the image
    img_hog = vl_hog(img, feature_params.hog_cell_size); % shape=[6,6,31]
    % feature is flattened HOG
    features_pos(i,:) = img_hog(:).';
    % visualize progress
    textprogressbar(i/num_samples*100);
end
textprogressbar(' done!');

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