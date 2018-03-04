function output = my_imfilter(image, filter)
% This function is intended to behave like the built in function imfilter()
% See 'help imfilter' or 'help conv2'. While terms like "filtering" and
% "convolution" might be used interchangeably, and they are indeed nearly
% the same thing, there is a difference:
% from 'help filter2'
%    2-D correlation is related to 2-D convolution by a 180 degree rotation
%    of the filter matrix.

% Your function should work for color images. Simply filter each color
% channel independently.

% Your function should work for filters of any width and height
% combination, as long as the width and height are odd (e.g. 1, 7, 9). This
% restriction makes it unambigious which pixel in the filter is the center
% pixel.

% Boundary handling can be tricky. The filter can't be centered on pixels
% at the image boundary without parts of the filter being out of bounds. If
% you look at 'help conv2' and 'help imfilter' you see that they have
% several options to deal with boundaries. You should simply recreate the
% default behavior of imfilter -- pad the input image with zeros, and
% return a filtered image which matches the input resolution. A better
% approach is to mirror the image content over the boundaries for padding.

% % Uncomment if you want to simply call imfilter so you can see the desired
% % behavior. When you write your actual solution, you can't use imfilter,
% % filter2, conv2, etc. Simply loop over all the pixels and do the actual
% % computation. It might be slow.
% output = imfilter(image, filter);


%%%%%%%%%%%%%%%%
% Your code here
%%%%%%%%%%%%%%%%
filter_size = size(filter);
f_pad1 = (filter_size(1)-1)/2;
f_pad2 = (filter_size(2)-1)/2;
total_size = size(image);
if length(total_size)==2,    channel = 1;
else   channel = total_size(3); end
image_size = total_size(1:2); % do not take channel dimension into consideration
if channel==3,
    % perform zero padding over image for every channel, for later on convolution
    image_padded_c1 = padarray(image(:,:,1), [f_pad1 f_pad2]);
    image_padded_c2 = padarray(image(:,:,2), [f_pad1 f_pad2]);
    image_padded_c3 = padarray(image(:,:,3), [f_pad1 f_pad2]);
    % three channels of filtered image, same size as original image
    output_c1 = zeros(image_size, 'single');
    output_c2 = zeros(image_size, 'single');
    output_c3 = zeros(image_size, 'single');
elseif channel==1,
    % perform zero padding over image for every channel, for later on convolution
    image_padded_c1 = padarray(image(:,:), [f_pad1 f_pad2]);
    % three channels of filtered image, same size as original image
    output = zeros(image_size, 'single');
else
    error('can only handle image with channel=1 or 3')
end
% perform filtering(correlation)
for i = 1:1:image_size(1),
    for j = 1:1:image_size(2),
        % compute region associated with filtering at location (i, j)
        i_ROI = i:(i + 2*f_pad1);
        j_ROI = j:(j + 2*f_pad2);
        % compute correlation value (filtering) at (i,j) for each channel
        if channel==3, % color image
            output_c1(i,j) = sum(sum(filter.*image_padded_c1(i_ROI, j_ROI)));
            output_c2(i,j) = sum(sum(filter.*image_padded_c2(i_ROI, j_ROI)));
            output_c3(i,j) = sum(sum(filter.*image_padded_c3(i_ROI, j_ROI)));
        else % gray image
            output(i,j) = sum(sum(filter.*image_padded_c1(i_ROI, j_ROI)));
        end    
    end
end
% concatenate 3 channel to a final filtered image
if channel==3, % color image
    output = cat(3, output_c1, output_c2, output_c3);
end

end