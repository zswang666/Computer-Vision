function p_trans = homo_trans(p,H)

n = size(p,1);
p = [p,ones(n,1)];
p_trans = p * H.';
p_trans = [p_trans(:,1)./p_trans(:,3), p_trans(:,2)./p_trans(:,3)];

end