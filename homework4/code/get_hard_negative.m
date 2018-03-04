function features_neg = get_hard_negative(neg_examples, feature_params, hard_neg_idx)
num_samples = length(hard_neg_idx);

textprogressbar('Obtaining hard negative features: ');
features_neg = zeros(num_samples, (feature_params.template_size / feature_params.hog_cell_size)^2 * 31);
for i=1:num_samples,
    img = im2single(neg_examples{hard_neg_idx(i)});
    if ~isempty(img),
        % extract HOG from the image
        img_hog = vl_hog(img, feature_params.hog_cell_size); % shape=[6,6,31]
        % feature is flattened HOG
        features_neg(i,:) = img_hog(:).';
        % visualize progress
        textprogressbar(i/num_samples*100);
    end
end
textprogressbar(' done!');

end