function image_feats = get_phow_fisher_vector(image_paths,vocab_path)

load(vocab_path) % vocab={gmm_params}, vocab_size
N = length(image_paths);
PHOW_step = 5;

textprogressbar('calculating phow fisher vectors: ');
image_feats = zeros(N,2*n_gmm*128);
for i=1:N,
    % read an image
    img = single(imread(image_paths{i}));
    % obtain dense SIFTs of the image
    [~,PHOW_features] = vl_phow(img,'step',PHOW_step);
    % obtain fisher vector
    image_feats(i,:) = vl_fisher(single(PHOW_features),vocab{1},vocab{2},vocab{3});
    % visualize progress
    textprogressbar(i/N*100);
end
textprogressbar(' done!');

end