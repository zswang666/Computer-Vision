function features_pos = get_hard_positive(train_path_pos, feature_params, hard_pos_idx)
image_files = dir( fullfile( train_path_pos, '*.jpg') ); %Caltech Faces stored as .jpg
num_samples = length(hard_pos_idx);

textprogressbar('Obtaining hard positive features: ');
features_pos = zeros(num_samples, (feature_params.template_size / feature_params.hog_cell_size)^2 * 31);
for i=1:num_samples,
    % read image and perform preprocessing
    img = imread([train_path_pos, '/', image_files(hard_pos_idx(i)).name]);
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
end