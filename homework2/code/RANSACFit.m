function H = RANSACFit(p1, p2, match, maxIter, seedSetSize, maxInlierError, goodFitThresh )
%RANSACFit Use RANSAC to find a robust affine transformation
% Input:
%   p1: N1 * 2 matrix, each row is a point
%   p2: N2 * 2 matrix, each row is a point
%   match: M * 2 matrix, each row represents a match [index of p1, index of p2]
%   maxIter: the number of iterations RANSAC will run
%   seedNum: The number of randomly-chosen seed points that we'll use to fit
%   our initial circle
%   maxInlierError: A match not in the seed set is considered an inlier if
%                   its error is less than maxInlierError. Error is
%                   measured as sum of Euclidean distance between transformed 
%                   point1 and point2. You need to implement the
%                   ComputeCost function.
%
%   goodFitThresh: The threshold for deciding whether or not a model is
%                  good; for a model to be good, at least goodFitThresh
%                  non-seed points must be declared inliers.
%   
% Output:
%   H: a robust estimation of affine transformation from p1 to p2
%
%   
    % validate input argument
    N = size(match, 1);
    if N<3
        error('not enough matches to produce a transformation matrix')
    end
    if ~exist('maxIter', 'var'),
        maxIter = 200;
    end
    if ~exist('seedSetSize', 'var'),
%         seedSetSize = ceil(0.2 * N);
        seedSetSize = max(3, ceil(0.1 * N));
    end
    seedSetSize = max(seedSetSize,3);
    if ~exist('maxInlierError', 'var'),
        maxInlierError = 30;
    end
    if ~exist('goodFitThresh', 'var'),
%         goodFitThresh = floor(0.7 * N);
        goodFitThresh = ceil(0.3 * N);
    end

    % below is an obfuscated version of RANSAC. You don't need to
    % edit any of this code, just the ComputeError() function below.
    
    % define transformation function handle
%     transformation = @(Pt1, Pt2) (ComputeAffineMatrix(Pt1, Pt2));
    transformation = @(Pt1, Pt2) (ComputeHomoMatrix(Pt1, Pt2));
    H = eye(3);
    min_inliers_err = inf;
    for i=1:maxIter,
        % random sample points to fit the model
        [fit_match, valid_match] = part(match, seedSetSize);
        % find fit model using above sampled points(matches)
        fit_model = transformation(p1(fit_match(:,1),:), p2(fit_match(:,2),:));
        % compute error of performing fit model over validation points(matches)
        valid_err = ComputeError(fit_model, p1, p2, valid_match);
        valid_inliers = (valid_err <= maxInlierError);
        % total inliers(inliers in validation set and all points in fitting set bigger than threshold) 
        if sum(valid_inliers(:)) + seedSetSize >= goodFitThresh,
            all_inliers = [fit_match; valid_match(valid_inliers,:)];
            % recompute fit model using all inlier matches
            fit_model = transformation(p1(all_inliers(:,1),:), p2(all_inliers(:,2),:));
            % compute self error over all inliers set
            inliers_err = sum(ComputeError(fit_model, p1, p2, all_inliers));
            % for every iteration, we set H to best fit model(with smallest self error)
            if inliers_err < min_inliers_err,
                H = fit_model;
                min_inliers_err = inliers_err;
            end
        end
    end

    if sum(sum((H - eye(3)).^2)) == 0,
        disp('No RANSAC fit was found.')
    end
end

function dists = ComputeError(H, pt1, pt2, match)
% Compute the error using transformation matrix H to 
% transform the point in pt1 to its matching point in pt2.
%
% Input:
%   H: 3 x 3 transformation matrix where H * [x; y; 1] transforms the point
%      (x, y) from the coordinate system of pt1 to the coordinate system of
%      pt2.
%   pt1: N1 x 2 matrix where each ROW is a data point [x_i, y_i]
%   pt2: N2 x 2 matrix where each ROW is a data point [x_i, y_i]
%   match: M x 2 matrix, each row represents a match [index of pt1, index of pt2]
%
% Output:
%    dists: An M x 1 vector where dists(i) is the error of fitting the i-th
%           match to the given transformation matrix.
%           Error is measured as the Euclidean distance between (transformed pt1)
%           and pt2 in homogeneous coordinates.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                              %
%                                YOUR CODE HERE.                               %
%           Convert the points to a usable format, perform the                 %
%           transformation on pt1 points, and find their distance to their     %
%           MATCHING pt2 points.                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % hint: If you have an array of indices, MATLAB can directly use it to
    % index into another array. For example, pt1(match(:, 1),:) returns a
    % matrix whose first row is pt1(match(1,1),:), second row is 
    % pt1(match(2,1),:), etc. (You may use 'for' loops if this is too
    % confusing, but understanding it will make your code simple and fast.)
    
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                              %
%                                 END YOUR CODE                                %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if size(dists,1) ~= size(match,1) || size(dists,2) ~= 1
        error('wrong format');
    end
end

function [D1, D2] = part(D, splitSize)
    idx = randperm(size(D, 1));
    D1 = D(idx(1:splitSize), :);
    D2 = D(idx(splitSize+1:end), :);
end


