classdef increBA_computeH < handle
	properties
        nImg % number of images now stored in the object
        P % x,y coordinate of key points
        matchFn % match function
        match % key points match pairs between 2 images
        desc % descriptors of key points for all images
        bundleH % a set of projective matrix for all pairs image_i-image_j
        inliers % total inlier matches used in RANSAC
        in_stamp % stamp for inliers, if it's true, then inliers of the match is fixed
        RANSACmaxIter
	end
	methods
        function obj = increBA_computeH(img, matchFn, RANSACmaxIter)
            % check input arguement
            obj.nImg = length(img);
            if obj.nImg~=2 && obj.nImg~=3, error('Number of input images for increBA_computeH constructor must be 2 or 3.'); end
            if ~exist('matchFn', 'var'), matchFn = @SIFTSimpleMatcher; end
            % define match function
            obj.matchFn = matchFn;
            % initialize in_stamp
            obj.in_stamp = cell(obj.nImg,obj.nImg);
            % feature detection
            for i=1:obj.nImg,
                I = single(rgb2gray(img{i}));
                [f,d] = vl_sift(I) ;
                obj.P{i} = double(f(1:2,:)');
                obj.desc{i} = double(d');
            end
            % find match
            loop_pool = sortrows(combnk(1:obj.nImg,2)).';
            for i=loop_pool,
                obj.match{i(1),i(2)} = obj.matchFn(obj.desc{i(1)},obj.desc{i(2)});
            end
            % compute bundle projective matrices using RANSAC
            obj.RANSACmaxIter = RANSACmaxIter;
            obj.RANSACbundleFit();
        end
        function [] = update(obj,img)
            obj.nImg = obj.nImg + 1;
            % expand in_stamp
            obj.in_stamp = [obj.in_stamp, cell(obj.nImg-1,1)];
            obj.in_stamp = [obj.in_stamp; cell(1,obj.nImg)];
            % feature detection
            I = single(rgb2gray(img));
            [f,d] = vl_sift(I);
            obj.P{obj.nImg} = double(f(1:2,:)');
            obj.desc{obj.nImg} = double(d');
            % find new match
            for i=1:obj.nImg-1,
                obj.match{i,obj.nImg} = obj.matchFn(obj.desc{i}, obj.desc{obj.nImg});
            end
            % compute bundle projective matrices using RANSAC
            obj.RANSACbundleFit();
        end
        % DO NOT call this function outside the object
        function [] = RANSACbundleFit(obj)
            % validate input argument and define
            loop_pool = sortrows(combnk(1:obj.nImg,2)).';
            n_match = size(loop_pool,2); % n_match
            for i=loop_pool,
                N = size(obj.match{i(1),i(2)},1);
                if N<4
                    error('not enough matches to produce a transformation matrix')
                end
                seedSetSize{i(1),i(2)} = max(3, ceil(0.1 * N));
                goodFitThresh{i(1),i(2)} = ceil(0.7 * N);
                maxInlierError{i(1),i(2)} = 30;
            end
            if ~exist('maxIter', 'var'),
                maxIter = 200;
            end
            % start RANSAC for each match
            min_bundleH_err = inf;
            iter = 0;
            while (iter<n_match*obj.RANSACmaxIter),
                % get good samples for all matches
                for i=loop_pool,% loop through all possible matches(loop_pool)
                    if isempty(obj.in_stamp{i(1),i(2)}),% only unfixed inliers need to be sampled(determined by in_stamp)
                        j = 0; get_good_samples = 0;
                        while ~get_good_samples && j<=obj.RANSACmaxIter,% loop until we have good samples
                            % sample-->outputing total inliers, stored in obj.inliers cell array
                            [total_in, get_good_samples] = ...
                                    getTotalInliers(obj.P{i(1)}, obj.P{i(2)}, obj.match{i(1),i(2)}, ...
                                            seedSetSize{i(1),i(2)}, maxInlierError{i(1),i(2)}, goodFitThresh{i(1),i(2)});
                            if get_good_samples, obj.inliers{i(1),i(2)} = total_in; end
                            % update iteration number
                            j = j + 1;
                        end
                        if j>=maxIter, 
                            warning('Failed to get good sample at (%d,%d)',i(1),i(2));
                            obj.inliers{i(1),i(2)} = [];
                        end
                        iter = iter + j;
                    end
                end
                % now we have a set of good samples(each as a set of total inliers) for all matches
                % use them to compute a new bundleH and error
                R_H = computebundleHomo(obj.P, obj.inliers, obj.bundleH);
                now_err = computeBundleErr(R_H, obj.P, obj.inliers);
                if mean(now_err)<=min_bundleH_err, % if there is a better bundleH
                    % update bundleH
                    obj.bundleH = R_H;
                    % update min_bundleH_err
                    min_bundleH_err = now_err;
                end
            end
            % update inliers stamp
            for i=loop_pool,
                obj.in_stamp{i(1),i(2)} = true;
            end
        end
	end
end

function dists = ComputeError(H, pt1, pt2, match)
if isempty(match),
    dists = 0;
    return
end
% get coordinates of matched points1 and points2
match_pt1 = pt1(match(:,1),:);
match_pt2 = pt2(match(:,2),:);
% transform points1 to potentially being points2 using matrix H
trans_pt1 = [match_pt1, ones(size(match_pt1,1),1)]*(H.');
trans_pt1 = [trans_pt1(:,1)./trans_pt1(:,3), trans_pt1(:,2)./trans_pt1(:,3)];
% compute Euclideance distance between real points2 and predicted
% points2 (transformed from points1)
dists = sum((match_pt2 - trans_pt1).^2, 2);
dists = sqrt(dists);
end

function [all_inliers, get_good_sample] = getTotalInliers(p1, p2, match, seedSetSize, maxInlierError, goodFitThresh)
% initialize output
get_good_sample = false; all_inliers = [];
% random sample points to fit the model
[fit_match, valid_match] = part(match, seedSetSize);
% find fit model using above sampled points(matches)
fit_model = ComputeHomoMatrix(p1(fit_match(:,1),:), p2(fit_match(:,2),:));
% compute error of performing fit model over validation points(matches)
valid_err = ComputeError(fit_model, p1, p2, valid_match);
valid_inliers = (valid_err <= maxInlierError);
% total inliers(inliers in validation set and all points in fitting set bigger than threshold) 
if sum(valid_inliers(:)) + seedSetSize >= goodFitThresh,
    all_inliers = [fit_match; valid_match(valid_inliers,:)];
    get_good_sample = true;
end
end

function [D1, D2] = part(D, splitSize)
    idx = randperm(size(D, 1));
    D1 = D(idx(1:splitSize), :);
    D2 = D(idx(splitSize+1:end), :);
end    

function err = computeBundleErr(H, P, match)
loop_pool = sortrows(combnk(1:length(P),2)).';
err = [];
for i=loop_pool,
    err = cat(1, err, ComputeError(H{i(1),i(2)}, P{i(1)} ,P{i(2)}, match{i(1),i(2)}));
end
end