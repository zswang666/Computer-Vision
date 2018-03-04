function image_feats = get_sp_sifts(image_paths,vocab_path)
% image_paths is an N x 1 cell array of strings where each string is an
% image path on the file system.

% This function assumes that 'vocab.mat' exists and contains an N x 128
% matrix 'vocab' where each row is a kmeans centroid or visual word. This
% matrix is saved to disk rather than passed in a parameter to avoid
% recomputing the vocabulary every time at significant expense.

% image_feats is an N x d matrix, where d is the dimensionality of the
% feature representation. In this case, d will equal the number of clusters
% or equivalently the number of entries in each image's histogram.

load(vocab_path)
vocab_size = size(vocab, 2);
N = length(image_paths);
dSIFT_step = 5;
img = imread(image_paths{1}); sz = size(img);

textprogressbar('calculating spatial pyramid SIFTs: ');
L = 3;
n_blocks = 0;
for i=0:L-1, n_blocks = n_blocks + 2^(2*i); end
image_feats = zeros(N,vocab_size*(n_blocks));
for i=1:N,
    % read an image
    img = single(imread(image_paths{i}));
    % obtain dense SIFTs of the image
    [loc,SIFT_features] = vl_dsift(img,'step',dSIFT_step);
    % form histogram features with spatial pyramid
    spHist = get_spHist(SIFT_features,loc,vocab,L,sz);
    r_start = 1;
    for j=1:length(spHist),
        r_end = r_start + 2^(2*j-2)*vocab_size-1;
        tmp = reshape(spHist{j},[],vocab_size);
        image_feats(i,r_start:r_end) = reshape(tmp.',1,[]);
        r_start = r_end + 1;
    end
    % visualize progress
    textprogressbar(i/N*100);
end
textprogressbar(' done!');

end

function out = get_spHist(sift,loc,vocab,l,sz)
n_side = 2^(l-1);
vocab_size = size(vocab, 2);
spHist = zeros(n_side,n_side,vocab_size);
i_bin = round(sz(1)/n_side);
j_bin = round(sz(2)/n_side);
for i=1:n_side,
    for j=1:n_side,
        i_roi = loc(1,:)>(i-1)*i_bin & loc(1,:)<=i*i_bin;
        j_roi = loc(2,:)>(j-1)*j_bin & loc(2,:)<=j*j_bin;
        ij_sift = sift(:,i_roi&j_roi);
        
        for k=1:size(ij_sift,2),
            k_to_all_dist = vl_alldist2(single(ij_sift(:,k)),vocab,'L2');
            [~,min_idx] = min(k_to_all_dist);
            spHist(i,j,min_idx) = spHist(i,j,min_idx) + 1;
        end
        tmp = max(spHist(i,j,:));
        if tmp~=0,
            spHist(i,j,:) = spHist(i,j,:) / max(spHist(i,j,:));
        end
    end
end
out{l} = spHist;

for idx_l=l-1:-1:1,
    up_n_side = 2^(idx_l);
    sub_spHist = zeros(up_n_side/2,up_n_side/2,vocab_size);
    for i=1:up_n_side,
        for j=1:up_n_side,
            sub_i = ceil(i/2);
            sub_j = ceil(j/2);
            sub_spHist(sub_i,sub_j) = sub_spHist(sub_i,sub_j) + spHist(i,j);
        end
    end
    out{idx_l} = sub_spHist;
end
end