%% Clear all
clear
clc; close all; clc;

%% Load image
img{1} = imread('../data/yosemite4.jpg');
img{2} = imread('../data/yosemite2.jpg');
img{3} = imread('../data/yosemite1.jpg');

%% Matching
matchFn = @SIFTSimpleMatcher;
increBA_obj = increBA_computeH(img, matchFn, 500);

%%
img{4} = imread('../data/Hanging1.png');
increBA_obj.update(img{4});

img{5} = imread('../data/yosemite3.jpg'); % MelakwaLake1.png
increBA_obj.update(img{5});

img{6} = imread('../data/Hanging2.png');
increBA_obj.update(img{6});


%%
pano = myMultipleStich(img, increBA_obj.bundleH);

for i=1:length(pano),
    figure,
    imshow(pano{i});
end   

% saveFileName = 'BA123.jpg';
% % TRANSFORM = {increBA_obj.bundleH{1,2}, increBA_obj.bundleH{2,3}, increBA_obj.bundleH{3,4} };
% % MultipleStitch(img, TRANSFORM, saveFileName);
% 
% % TRANSFORM2 = {increBA_obj.bundleH{1,2},increBA_obj.bundleH{2,3}};
% % img2 = {img{1}, img{2}, img{3}};
% % MultipleStitch(img2, TRANSFORM2, saveFileName);
% 
% TRANSFORM3 = {inv(increBA_obj.bundleH{1,3}), increBA_obj.bundleH{1,2}, increBA_obj.bundleH{2,4} };
% img3 = {img{3}, img{1}, img{2}, img{4}};
% MultipleStitch(img3, TRANSFORM3, saveFileName);
% 
% % TRANSFORM3 = {increBA_obj.bundleH{1,2}};
% % img3 = {img{1}, img{2}};
% % MultipleStitch(img3, TRANSFORM3, saveFileName);
% 
% TRANSFORM5 = {increBA_obj.bundleH{5,6}};
% img5 = {img{5}, img{6}};
% MultipleStitch(img5, TRANSFORM5, 'extra.jpg');
% 
% disp(['The completed file has been saved as ' saveFileName]);
% figure,
% imshow(imread(saveFileName));
% figure,
% imshow(imread('extra.jpg'));