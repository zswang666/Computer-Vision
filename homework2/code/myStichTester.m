clear

% 3rd-party packages
% run('../vlfeat/toolbox/vl_setup');

% collect filenames in "../data" directory and disarange them
imgList = [dir('../data/yosemite*'); dir('../data/Rainier*'); dir('../data/MelakwaLake*')];
% imgList = [dir('../data/Hanging*'); dir('../data/uttower*')];
imgList = imgList(randperm(numel(imgList))); % randomly change the order of image list

% load images according to imgList
img = cell(1, length(imgList));
for i = 1 : length(imgList),
    img{i} = imread(['../data/' imgList(i).name]);
    % Resize to make memory efficient
    if max(size(img{i})) > 1000 || length(imgList) > 10,
        img{i} = imresize(img{i}, 0.7);
    end
end
disp('Images loaded. Beginning feature detection...');

% initialize object for computing homography matrix using incremental bundle adjustment 
matchFn = @SIFTSimpleMatcher;
RANSACmaxIter = 500;
first3_img = {img{1:3}};
increBA_obj = increBA_computeH(first3_img, matchFn, RANSACmaxIter);

% incrementally compute homography matrix using bundle adjustment
other_img = {img{4:end}};
for i=1:length(other_img),
    increBA_obj.update(other_img{i});
end

% stich all images to make Panoramic image
disp('Stitching images...')
pano = myMultipleStich(img, increBA_obj.bundleH);

% display all paranomas
for i=1:length(pano),
    figure,
    imshow(pano{i});
end