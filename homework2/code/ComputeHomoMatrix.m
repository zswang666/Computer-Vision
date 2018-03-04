function H = ComputeHomoMatrix( Pt1, Pt2 )
%ComputeHomoMatrix 
%   Computes the transformation matrix that transforms a point from
%   coordinate frame 1 to coordinate frame 2
%Input:
%   Pt1: N * 2 matrix, each row is a point in image 1 
%       (N must be at least 3)
%   Pt2: N * 2 matrix, each row is the point in image 2 that 
%       matches the same point in image 1 (N should be more than 3)
%Output:
%   H: 3 * 3 homography transformation matrix, 
%       such that H*pt1(i,:) = pt2(i,:)

% validate arguments
n = size(Pt1,1);
if size(Pt1, 1) ~= size(Pt2, 1),
    error('Dimensions unmatched.');
elseif n<3
    error('At least 3 points are required.');
end

% Convert the input points to homogeneous coordintes.
P1 = [Pt1, ones(n,1)];
P2 = [Pt2, ones(n,1)];

%%% solving homography matrix using SVD.

% forming homogenious linear least square problem Ah = 0, where h is the
% flattened vector of transpose of H
zero3_mat = zeros(n,3);
Ax = [-P1, zero3_mat, P2(:,1).*P1(:,1), P2(:,1).*P1(:,2), P2(:,1)];
Ay = [zero3_mat, -P1, P2(:,2).*P1(:,1), P2(:,2).*P1(:,2), P2(:,2)];
A = zeros(size(Ax,1)*2, size(Ax,2));
A(1:2:end,:) = Ax;
A(2:2:end,:) = Ay;
% find singular vectors of A
[~,~,V] = svd(A);
% h is the singular vector corresponding to the smallest eigenvalue sigma_9
% note that Matlab "svd" outputs sigma with a descending order, giving the
% target singular vector be the last column of singular vector matrix V.
H = (reshape(V(:,end),3,3)).';

%%% solving homography matrix using levenberg-marquardt algorithm
%     % define objective function with output as residual to be minimized
%     function r = Ah(h_tmp)
%         H_tmp_t = reshape(h_tmp(:,end),3,3);
%         P1_trans = (P1 * H_tmp_t);
%         P1_trans = [P1_trans(:,1)./P1_trans(:,3) P1_trans(:,2)./P1_trans(:,3) ones(n,1)];
%         r = sum(abs(P1_trans - P2),2);
%     end
% h = eye(3); h = h(:); % initial guess
% options = optimoptions('lsqnonlin','display','none','Algorithm','levenberg-marquardt','MaxFunEvals',1e3);
% h = lsqnonlin(@Ah,h,[],[],options);
% 
% H = (reshape(h(:,end),3,3)).';

end