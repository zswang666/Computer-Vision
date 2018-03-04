function [bundleH] = computebundleHomo(P,match,h_init)
% input:
%     P: a cell array with each cell as all keypoints of an image
%     match: a cell array with (i,j) entry as match points index of i_th
%            and j_th images. Note that always i<j.
%     h_init: a cell array defining initial guess

% number of image in this bundle
nImg = length(P);
% sigma of huber error, used to determine outlier distance tolerance, TEST
huberSig = 128 / 2^nImg;

loop_pool = sortrows(combnk(1:nImg,2)).';
n_match = size(loop_pool,2);

pi_matchj = cell(nImg-1,nImg);
for i=loop_pool,
    if ~isempty(match{i(1),i(2)}),
        % in the match of i_th and j_th images, pi_matchj{i,j} is all points in
        % i_th image matching to j_th image.
        pi_matchj{i(1),i(2)} = P{i(1)}(match{i(1),i(2)}(:,1),:);
        pi_matchj{i(2),i(1)} = P{i(2)}(match{i(1),i(2)}(:,2),:);
        % convert to homogeneous coordinate
        pi_matchj{i(1),i(2)} = [pi_matchj{i(1),i(2)}, ones(size(pi_matchj{i(1),i(2)},1),1)];
        pi_matchj{i(2),i(1)} = [pi_matchj{i(2),i(1)}, ones(size(pi_matchj{i(2),i(1)},1),1)];
    else
        pi_matchj{i(1),i(2)} = [];
    end
end

if nImg<=3,
    h_init = [];
    for i=loop_pool,
        if ~isempty(match{i(1),i(2)}),
            H = ComputeHomoMatrix(pi_matchj{i(1),i(2)}(:,1:2), pi_matchj{i(2),i(1)}(:,1:2));
            h_init = cat(1, h_init, reshape(H.',9,1));
        end
    end
else
    for i=1:nImg-1,
        if ~isempty(match{i,nImg}),
        	h_init{i,nImg} = ComputeHomoMatrix(pi_matchj{i,nImg}(:,1:2), pi_matchj{nImg,i}(:,1:2));
        else
            h_init{i,nImg} = [];
        end
    end
    % convert from cell array to vector
    h_tmp = h_init;
    h_init = [];
    for i=loop_pool,
        if ~isempty(h_tmp{i(1),i(2)}),
            h_init = cat(1,h_init,reshape(h_tmp{i(1),i(2)}.',9,1));
        end
    end
end

    % define residual function
    function r = computeR(h)
        h = reshape(h,9,[]).';
%         assert( size(h,1)==n_match );
        r = [];
        j_c = 1;
        for i_c=loop_pool,
            if ~isempty(match{i_c(1),i_c(2)}),
                % transpose of H
                H_t = reshape(h(j_c,:),3,3); 
                j_c = j_c + 1;
                % points fransform from i_c(1) images to i_c(1) coordinate
                p_trans = pi_matchj{i_c(1),i_c(2)} * H_t;
                % avoid dividing 0
                if abs(H_t(3,3))<1e-5, r = cat(1,r,1000*ones(size(p_trans,1),1)); continue; end 
                % use standard homogeneous coordinate
                p_trans = [p_trans(:,1)./p_trans(:,3) p_trans(:,2)./p_trans(:,3) ones(size(p_trans,1),1)];
                % append new residual vector associated with current match
                r_tmp = sum(abs(p_trans - pi_matchj{i_c(2),i_c(1)}),2);
                r_tmp = huberError(r_tmp,huberSig);
                r = cat(1,r,r_tmp);
            end
        end
    end
% solve min(residual) by levenberg-marquardt algorithm
funMaxIter = min(10^(4+nImg),5*10^8);
options = optimoptions('lsqnonlin','display','none','Algorithm','levenberg-marquardt','MaxFunEvals',funMaxIter);
options.TolX = 1e-13;
options.TolFun = 1e-13;
[h,ssq,iter] = lsqnonlin(@computeR,h_init,[],[],options);

j = 0;
bundleH = cell(nImg-1,nImg);
for i=loop_pool,
    if ~isempty(match{i(1),i(2)}),
        bundleH{i(1),i(2)} = (reshape(h(j+1:j+9),3,3)).';
        j = j + 9;
    else
        bundleH{i(1),i(2)} = [];
    end
end

end

function fx = huberError(x,sig)
    condition = (x<=sig);
    fx = x.*condition + sqrt(2*sig*x-sig^2).*(~condition);
end