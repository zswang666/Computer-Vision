% Starter code prepared by James Hays
% This function returns detections on all of the images in a given path.
% You will want to use non-maximum suppression on your detections or your
% performance will be poor (the evaluation counts a duplicate detection as
% wrong). The non-maximum suppression is done on a per-image basis. The
% starter code includes a call to a provided non-max suppression function.
function [bboxes, confidences, image_ids] = .... 
    run_detector(test_scn_path, w, b, feature_params)
% 'test_scn_path' is a string. This directory contains images which may or
%    may not have faces in them. This function should work for the MIT+CMU
%    test set but also for any other images (e.g. class photos)
% 'w' and 'b' are the linear classifier parameters
% 'feature_params' is a struct, with fields
%   feature_params.template_size (probably 36), the number of pixels
%      spanned by each train / test template and
%   feature_params.hog_cell_size (default 6), the number of pixels in each
%      HoG cell. template size should be evenly divisible by hog_cell_size.
%      Smaller HoG cell sizes tend to work better, but they make things
%      slower because the feature dimensionality increases and more
%      importantly the step size of the classifier decreases at test time.

% 'bboxes' is Nx4. N is the number of detections. bboxes(i,:) is
%   [x_min, y_min, x_max, y_max] for detection i. 
%   Remember 'y' is dimension 1 in Matlab!
% 'confidences' is Nx1. confidences(i) is the real valued confidence of
%   detection i.
% 'image_ids' is an Nx1 cell array. image_ids{i} is the image file name
%   for detection i. (not the full path, just 'albert.jpg')

% The placeholder version of this code will return random bounding boxes in
% each test image. It will even do non-maximum suppression on the random
% bounding boxes to give you an example of how to call the function.

% Your actual code should convert each test image to HoG feature space with
% a _single_ call to vl_hog for each scale. Then step over the HoG cells,
% taking groups of cells that are the same size as your learned template,
% and classifying them. If the classification is above some confidence,
% keep the detection and then pass all the detections for an image to
% non-maximum suppression. For your initial debugging, you can operate only
% at a single scale and you can skip calling non-maximum suppression.

step = 3;
level = 6;
scale_rate = 0.8;
confidence_thresh = 1;

block_hog_fun = @(block_struct) vl_hog(block_struct.data, feature_params.hog_cell_size);
block_loc_fun = @(block_struct) block_struct.location;
border_size = max(0,round((36-step)/2));

test_scenes = dir( fullfile( test_scn_path, '*.jpg' ));

%initialize these as empty and incrementally expand them.
bboxes = zeros(0,4);
confidences = zeros(0,1);
image_ids = cell(0,1);

n_samples = length(test_scenes);
textprogressbar('Running detector: ');
for i = 1:n_samples,
      
%     fprintf('Detecting faces in %s\n', test_scenes(i).name)
    img = imread( fullfile( test_scn_path, test_scenes(i).name ));
    if(size(img,3) > 1)
        img = rgb2gray(img);
    end
    
    % multi-scale
    cur_confidences = [];
    cur_bboxes = [];
    cur_image_ids = [];
    for l=1:level,
        % downsample image according to current level
        now_scale = scale_rate^(l-1);
        img_downsampled = imresize(img, now_scale);
        % make sure size of downsampled images are larger than template_size
        if all(size(img_downsampled)>=[feature_params.template_size,feature_params.template_size]),
            % do sliding window
            % obtain bbox
            loc = blockproc(img_downsampled, [step step], block_loc_fun, ...
                            'BorderSize', [border_size border_size], ...
                            'TrimBorder', false, 'PadPartialBlocks', true);
            xcent = loc(:,2:2:end); xcent = xcent(:);
            ycent = loc(:,1:2:end); ycent = ycent(:);
            xmin = max(1, xcent-15);
            ymin = max(1, ycent-15);
            d_sz = size(img_downsampled);
            xmax = min(d_sz(2), xcent+20);
            ymax = min(d_sz(1), ycent+20);
            tmp_bboxes = [xmin, ymin, xmax, ymax];
            % do scaling
            tmp_bboxes = (tmp_bboxes-1)/now_scale + 1;

            % obtain block HOG
            img_downsampled = im2single(img_downsampled);
            grid_hog = blockproc(img_downsampled, [step step], block_hog_fun, ...
                                 'BorderSize', [border_size border_size], ...
                                 'PadMethod', 'symmetric', ...
                                 'TrimBorder', false, 'PadPartialBlocks', true);
            if all(~(mod(size(grid_hog(:,:,1)),feature_params.hog_cell_size))),
                dim1 = size(grid_hog,1) / feature_params.hog_cell_size;
                dim2 = size(grid_hog,2) / feature_params.hog_cell_size;
                % convert to dim1*dim2 cell array with each cell as 6 x 6 x 31 matrix
                block_hog = mat2cell(grid_hog, repmat(feature_params.hog_cell_size,dim1,1), ...
                                     repmat(feature_params.hog_cell_size,dim2,1), 31);
                % convert to dim1 x dim2 cell array with each cell as (6*6*31) x 1 matrix 
                block_hog = cellfun(@(x) x(:).', block_hog, 'UniformOutput', false);
                % convert to (dim1*dim2) x (6*6*31) matrix
                block_hog = vertcat(block_hog{:});
            else
                error('Size of grid_hog is not the multiplies of hog_cell_size!');
            end
            % compute confidences of all bbox in current image using SVM inference
            tmp_confidences = block_hog*w + b;

            % prefiltering by confidence
            msk = tmp_confidences>=confidence_thresh;
            tmp_confidences = tmp_confidences(msk,:);
            tmp_bboxes = tmp_bboxes(msk,:);

            tmp_image_ids = cell(size(tmp_bboxes,1),1);
            tmp_image_ids(:,1) = {test_scenes(i).name};
            
            % append to currents
            cur_confidences = [cur_confidences; tmp_confidences];
            cur_bboxes = [cur_bboxes; tmp_bboxes];
            cur_image_ids = [cur_image_ids; tmp_image_ids];
        end   
    end
    
    % non_max_supr_bbox can actually get somewhat slow with thousands of
    % initial detections. You could pre-filter the detections by confidence,
    % e.g. a detection with confidence -1.1 will probably never be
    % meaningful. You probably _don't_ want to threshold at 0.0, though. You
    % can get higher recall with a lower threshold. You don't need to modify
    % anything in non_max_supr_bbox, but you can.
    [is_maximum] = non_max_supr_bbox(cur_bboxes, cur_confidences, size(img));

    cur_confidences = cur_confidences(is_maximum,:);
    cur_bboxes      = cur_bboxes(     is_maximum,:);
    cur_image_ids   = cur_image_ids(  is_maximum,:);
 
    bboxes      = [bboxes;      cur_bboxes];
    confidences = [confidences; cur_confidences];
    image_ids   = [image_ids;   cur_image_ids];
    
    % visualize progress
    textprogressbar(i/n_samples*100);
end
textprogressbar(' done!');

end