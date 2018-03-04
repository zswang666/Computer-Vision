function pano = myMultipleStich(img, bundleH)

% form a graph matrix according to entries of cell array bundleH
G{1} = ~cellfun(@isempty, bundleH);
n_img = size(G{1},2);
G{1} = [G{1}; zeros(1,n_img)];
G{1} = sparse(G{1} + G{1}.');

% split merged graph G{1} into numerous possible independent graphs
i = 1;
while(~isequal(G{i},zeros(n_img,n_img))),
    % find a path that traverse all nodes of an independent graph
    start = find(G{i});  start = floor(start(1)/n_img)+1;
    G_trav = graphtraverse(G{i},start);
    % obtain all possible edges of the extracted graph according to the traverse 
    extract_idx = combnk(G_trav,2);
    extract_idx = [extract_idx; [extract_idx(:,2) extract_idx(:,1)]];
    % get extracted graph
    G_new = zeros(n_img,n_img);  
    G_new(extract_idx(:,1),extract_idx(:,2)) = 1;
    G_new = G_new .* G{i};
    % extract graph from the merged graph 
    G{i+1} = G{i} - G_new;
    G{i} = G_new;
    i = i + 1;
end
G = G(1:i-1);
n_pano = length(G); % number of panoroma, may not be 1

% for each graph, find the best reference image and compute transformation wrt. ref 
TtoRef = cell(1,n_pano);
for i=1:n_pano,
    % split bundleH corresponding to current panoroma,
    split_bundleH = cell(n_img-1,n_img);
    for a=1:n_img-1, % can find a better way
        for b=1:n_img,
            if G{i}(a,b),
                split_bundleH{a,b} = bundleH{a,b};
            end
        end
    end
    
    % get reference, undone
    ref{i} = find(G{i});
    ref{i} = mod(ref{i}(1), n_img);
    if ref{i}==0, ref{i} = n_img; end;
    
    % find shortest path to get transformation wrt reference
    % path{i}{j}-->in i_th panoroma, path from ref to j_th node
    [~,myPath] = graphshortestpath(G{i},ref{i});
    % get all transformations from non-ref images to reference image
    TtoRef{i} = getTfromRef(split_bundleH, myPath, ref{i});
end

% for i_th paranoma, TtoRef{i}{j} is the transformation from ref{i} img to
% j_th image. If TtoRef{i}{j} is [], then ref{i} img and j_th img are not
% in the same paranoma.

% for each panoroma, we now have transformation from every image to reference
% coordinate. We can then stich images to form panoroma
for i=1:n_pano,
    % define output(panoroma) bound
	outBounds = zeros(2,2);
    outBounds(1,:) = Inf;
    outBounds(2,:) = -Inf; 
    % estimate the largest possible panorama size
    [nrows, ncols, ~] = size(img{ref{i}});
    nrows = length(img) * nrows;
    ncols = length(img) * ncols;
    % find output spatial bound for every transformation
    for j=1:length(TtoRef{i}),
        if ~isempty(TtoRef{i}{j}),
            tmpBounds = findbounds(maketform('projective', TtoRef{i}{j}'), [1 1; ncols nrows]);
            outBounds(1,:) = min(outBounds(1,:),tmpBounds(1,:));
            outBounds(2,:) = max(outBounds(2,:),tmpBounds(2,:));
        end
    end
    % extra constraints in order to avoid memory exceeding
    outBounds(1,:) = max(outBounds(1,:), -2000);
    outBounds(2,:) = min(outBounds(2,:), 2000);
    % Stitch the reference image.
    XdataLimit = round(outBounds(:,1)');
    YdataLimit = round(outBounds(:,2)');
    pano{i} = imtransform( im2double(img{ref{i}}), maketform('projective', eye(3)), 'bilinear', ...
                        'XData', XdataLimit, 'YData', YdataLimit, ...
                        'FillValues', NaN, 'XYScale',1);
    % Stitch the non-reference image.                
    for j=1:length(TtoRef{i}),
        if ~isempty(TtoRef{i}{j}) && j~=ref{i},
            Tform = maketform('projective', TtoRef{i}{j}');
            AddOn = imtransform(im2double(img{j}), Tform, 'bilinear', ...
                        'XData', XdataLimit, 'YData', YdataLimit, ...
                        'FillValues', NaN, 'XYScale',1);
            result_mask = ~isnan(pano{i}(:,:,1));
            temp_mask = ~isnan(AddOn(:,:,1));
            add_mask = temp_mask & (~result_mask);

            for c = 1 : size(pano{i},3),
                cur_im = pano{i}(:,:,c);
                temp_im = AddOn(:,:,c);
                cur_im(add_mask) = temp_im(add_mask);
                pano{i}(:,:,c) = cur_im;
            end
        end
    end
    % Cropping the final panorama to leave out black spaces.
    [I, J] = ind2sub([size(pano{i}, 1), size(pano{i}, 2)], find(~isnan(pano{i}(:, :, 1))));
    upper = max(min(I)-1, 1);
    lower = min(max(I)+1, size(pano{i}, 1));
    left = max(min(J)-1, 1);
    right = min(max(J)+1, size(pano{i}, 2));
    pano{i} = pano{i}(upper:lower, left:right,:);
end

end

function TtoRef = getTfromRef(bundleH, path, ref)
    n_nodes = size(bundleH, 2);
    TtoRef = cell(1,n_nodes);
    for i=1:n_nodes,
        if ~isempty(path{i}),
            TtoRef{i} = eye(3);
            if i~=ref,
                for j=length(path{i}):-1:2,
                    if path{i}(j)<path{i}(j-1),
                        TtoRef{i} = bundleH{path{i}(j),path{i}(j-1)} * TtoRef{i};
                    else
                        TtoRef{i} = inv(bundleH{path{i}(j-1),path{i}(j)}) * TtoRef{i};
                    end
                end
            end
        else
            TtoRef{i} = [];
        end
    end
end