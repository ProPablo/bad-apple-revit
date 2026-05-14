%% INIT
clear; close all;

img = imread('ocr_test.jpg');
figure
imshow(img)
% line = drawline;
grayImg = rgb2gray(img);

%% Manually get angle and adjust
% These values are all based on ocr_test_2

linePos = [[0.5	1113.5];
[3024.5	1053.5]];
y1 = linePos(1, 2);
y2 = linePos(2, 2);

x1 = linePos(1, 1);
x2 = linePos(2, 1);

angle = rad2deg( atan2(y2 - y1, x2 - x1));

%angle = 0.1;
%rot_img = imrotate(img, angle);
%figure 
%imshow(rot_img)

%% Selecting Details box

% Create mask of JUST details


% Convert RGB image to HSV
I = rgb2hsv(img);
  
channel1Min = 0.380;
channel1Max = 0.531;

channel2Min = 0.204;
channel2Max = 1.000;

channel3Min = 0.592;
channel3Max = 1.000;

% Create mask based on chosen histogram thresholds
sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW_HSV = sliderBW;

% Create better mask with LAB (more expensive)
% Convert RGB image to chosen color space
I = rgb2lab(img);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.000;
channel1Max = 100.000;

% Define thresholds for channel 2 based on histogram settings
channel2Min = -61.360;
channel2Max = -26.210;

% Define thresholds for channel 3 based on histogram settings
channel3Min = -31.648;
channel3Max = 34.659;

% Create mask based on chosen histogram thresholds
sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW = sliderBW;

%BW = BW_HSV; % Force select HSV instead 
figure
montage({grayImg, BW_HSV, BW})
 

% Do blob detection and filter small blobs
figure
[B,L] = bwboundaries(BW,'noholes');
imshow(label2rgb(L, @jet, [.5 .5 .5]))

figure 
imshow(BW);
hold on;
BW2 = bwareafilt(BW, [3000, 50000]); %Filter out overly small and large blobs
% ABove might not be necessary with imopen

%% Perform some morphology for getting details region
m = 360; n = 90;

SE_open = strel("rectangle",[n m] .* 0.1);


figure
imshow(BW2)

% The open operation makes us lose our angle so we have to be mindful of that
% On second thought angle is not needed, use phone gyro
BW3 = imopen(BW2, SE_open); 

figure 
imshow(BW3)

SE_close = strel("rectangle",[n m] .* 1.2);
BW4 = imclose(BW3, SE_close);

figure 
imshow(BW4)

figure;
montage({BW2, BW3, BW4}, "Size", [1 3], "BorderSize", 3, "BackgroundColor", "red");


% ACTUAL blob detection that is done better than before because it is
% affected by morphology (no text in boxes)
CC = bwconncomp(BW4);
stats = regionprops(CC, "all");
roi = vertcat(stats(:).BoundingBox);

figure
L4 = labelmatrix(CC);
RGB_label = label2rgb(L4,@copper,"c","shuffle");
imshow(RGB_label)

numAdditionalPixels = 5;
roi(:,1:2) = roi(:,1:2) - numAdditionalPixels;
roi(:,3:4) = roi(:,3:4) + 2*numAdditionalPixels;

imgHeight = size(img, 1);
imgWidth = size(img, 2);

% Clamp x and y (columns 1 and 2) to be at least 1
roi(:,1) = max(roi(:,1), 1);
roi(:,2) = max(roi(:,2), 1);

% Clamp width and height so x+w-1 and y+h-1 don't exceed image dimensions
roi(:,3) = max(min(roi(:,3), imgWidth  - roi(:,1) + 1), 1);
roi(:,4) = max(min(roi(:,4), imgHeight - roi(:,2) + 1), 1);

% Ensure ROI values are integer for image processing functions
roi = round(roi);

roi_img = insertShape(img,"rectangle",roi,LineWidth=4);


%% OCR Preprocessing
Icorrected = imbothat(img,strel("disk",15));

% gaus filter to reduce LED screen noise
Ifiltered = imgaussfilt(Icorrected, 1);

BW = rgb2gray(Ifiltered);
BW1 = imbinarize(BW);

% morphological filtering (no reconstruction as some letters are non
% contiguous)
BW2 = bwareaopen(BW1, 5);

% Black text on white background preferred for OCR
BW3 = imcomplement(BW2);

figure 
montage({roi_img, BW1, BW2, BW3}, "BorderSize", 3, "BackgroundColor", "red");
figure
imshow(BW3)
%% OCR
results = ocr(BW3,roi, LayoutAnalysis="block");

text = strip(replace({results.Text}, newline, ''))
annotated_img  = insertObjectAnnotation(img,"rectangle",roi,text, "FontSize", 20, "LineWidth", 5);

figure; 
imshow(annotated_img)
% Filter to only get the blob with 'details'

correct_roi_idx = contains(text, "Details");
correct_roi = roi(correct_roi_idx, :);
correct_roi = correct_roi(1, :); % Only need first detection

%%


%% Create offsets for score OCR
% Again thise are values based on ocr_test_2 rotated to be aliigned
% values will have to be normalized into UV coords relative to details top
% right and width and height of details box

% Raw offsets
top_left_details = [2054,2345];
bot_right_details = [2417,2454];

top_left_score = [2700 2551];
bot_right_score = [2953, 2611];

top_left_difficulty = [1657,2471];

% processed 
score_box_size = [bot_right_score(1) - top_left_score(1), bot_right_score(2) - top_left_score(2)] % [width, height]
score_offset = top_left_score - top_left_details %b(dest) - a (origin)

difficulty_offset = top_left_difficulty - top_left_details;
difficulty_box_size = [score_box_size(1) * 0.8, score_box_size(2)];

% rois
score_roi = [correct_roi(1:2) + score_offset , score_box_size];
score_roi(:,1:2) = score_roi(:,1:2) - numAdditionalPixels;
score_roi(:,3:4) = score_roi(:,3:4) + 2*numAdditionalPixels;

difficulty_roi = [correct_roi(1:2) + difficulty_offset , difficulty_box_size];
difficulty_roi(:,1:2) = difficulty_roi(:,1:2) - numAdditionalPixels;
difficulty_roi(:,3:4) = difficulty_roi(:,3:4) + 2*numAdditionalPixels;

figure
annotated_img2  = insertObjectAnnotation(annotated_img,"rectangle",[score_roi; difficulty_roi],["score_roi", "difficulty_roi"], "FontSize", 20, "LineWidth", 5);
imshow(annotated_img2)

%% Using regionprops Convex hull method instead (bwboundary only gives boundary PIXELS)
CC = bwconncomp(BW4);
stats = regionprops(CC, "all");

% Display original image
figure;
imshow(img);
hold on;

% Draw all contours
for i = 1:length(stats)
    % Draw ConvexHull
    hull = stats(i).ConvexHull;
    plot(hull(:,1), hull(:,2), 'g-', 'LineWidth', 2);
    
    % Optionally draw extrema points
    extrema = stats(i).Extrema;
    plot(extrema(:,1), extrema(:,2), 'r*', 'MarkerSize', 10);
end

% Select the biggest and simplify
% Find the largest region (likely the document)
% [~, idx] = max([stats.Area]);

idx = find(correct_roi_idx);
%idx = 5;

boundary = stats(idx).ConvexHull;  % Nx2 matrix of boundary points 
% (indexing a prop like this just gets the first one even though idx has 2 memebers)

% Approximate polygon (Douglas-Peucker algorithm) (Do this to reduce
% verteces down to 4)
perimeter = stats(idx).Perimeter;
epsilon = 0.1;
approx = reducepoly(boundary, epsilon);

% Draw approximated polygon with different color for each edge
colors = lines(size(approx, 1));
for i = 1:size(approx, 1)
    nextIdx = mod(i, size(approx, 1)) + 1;
    plot([approx(i,1), approx(nextIdx,1)], [approx(i,2), approx(nextIdx,2)], ...
        'Color', colors(i,:), 'LineWidth', 4);
end

% Draw vertices
plot(approx(:,1), approx(:,2), 'ko', 'MarkerSize', 12, 'MarkerFaceColor', 'yellow');

pts = approx(1:4, :);
% Order points: top-left, top-right, bottom-right, bottom-left
[~, idx] = sort(sum(pts, 2));  % sum of x+y
tl = pts(idx(1), :);  % smallest sum = top-left
br = pts(idx(end), :); % largest sum = bottom-right

remaining = pts(idx(2:3), :);
[~, idx2] = sort(remaining(:,1));
tr = remaining(idx2(2), :);  % larger x = top-right
bl = remaining(idx2(1), :);  % smaller x = bottom-left

ordered = [tl; tr; br; bl];

%% Perform homography according to details reference points from rotated ocr_test_2

% Create the 4 reference corner points
ref_tl = top_left_details;
ref_tr = [bot_right_details(1), top_left_details(2)];
ref_br = bot_right_details;
ref_bl = [top_left_details(1), bot_right_details(2)];

% Reference points in same order as your detected corners
referencePoints = [ref_tl; ref_tr; ref_br; ref_bl];

% Compute homography
tform = fitgeotrans(ordered, referencePoints, 'projective');

% Apply perspective transform
[warpedImg, RB] = imwarp(img, tform);

figure 
montage({img, warpedImg})

figure
imshow(warpedImg);

%% Read from offsets

[xdataT,ydataT]=transformPointsForward(tform,tl(1), tl(2));
[t1x,t1y]=worldToIntrinsic(RB,xdataT,ydataT);

warped_details_top_left = [t1x, t1y];
score_roi = [warped_details_top_left + score_offset , score_box_size];

score_roi  = expandRoi(score_roi);
%% OCR
img_cropped = imcrop(warpedImg, score_roi);
Icorrected = imtophat(img_cropped,strel("disk",15)); % Really helps with eliminating similarity with background (check main resource)
BW1 = imbinarize(Icorrected);

figure 
montage({img_cropped, Icorrected, BW1})

% Perform morphological reconstruction and show binarized image.
marker = imerode(Icorrected,strel("line",10,0));
Iclean = imreconstruct(marker,Icorrected);

Ibinary = imbinarize(Iclean);

figure
montage({marker, Iclean, Ibinary})

BW2 = imcomplement(Ibinary);
figure
imshowpair(Ibinary,BW2,"montage")


results = ocr(BW2,LayoutAnalysis="none");
score = string(strip(replace({results.Text}, {newline, ',', '.'}, "")));
score = str2num(score)

%% Difficulty
difficulty_roi = [warped_details_top_left + difficulty_offset , difficulty_box_size];

difficulty_roi = expandRoi(difficulty_roi);

img_cropped = imcrop(warpedImg, difficulty_roi);

figure
imshowHist(img_cropped);

% thresholding
I = rgb2hsv(img_cropped);
% Just thresholding Value
channel3Min = 0.53;
channel3Max = 1.000;

% Create mask based on chosen histogram thresholds
sliderBW = (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW1 = sliderBW;
gray = rgb2gray(img_cropped);
BW2 = imbinarize(gray);
BW3 = imcomplement(BW1);



masked_img_cropped = img_cropped;
% Set background pixels where BW is false to zero.
masked_img_cropped(repmat(~BW1,[1 1 3])) = 0; % The "value" now has a bucket at 0 that is very high here because of all the black 
% but the hue matches closely to the target bucket
figure
imshowHist(masked_img_cropped);

% Should binarize better here using LAB OR use histogram buckets after
% simple thresholding to get most prominent hue

I = rgb2lab(img_cropped);
channel1Min = 40.381;
channel1Max = 84.895;
sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max);
BW4 = sliderBW;

figure
montage({img_cropped, BW1, BW2, BW3});

figure 
imshow(BW4)

results = ocr(BW4,LayoutAnalysis="block"); % Block is better here since there is a very likely chance theres a lot of stuff on the outside 
difficulty = string(strip(replace({results.Text}, {newline}, "")))

%% Full details box for scores OCR

% Doesnt work that well
% Raw offsets
% top_left_all_scores = [1561,2550];
% bot_right_all_scores = [2020,2910];

top_left_all_scores = [1700,2550];
bot_right_all_scores = [2010,2910];

all_scores_size = bot_right_all_scores - top_left_all_scores;
all_scores_offset = top_left_all_scores - top_left_details; %b(dest) - a (origin)

% rois
all_scores_roi = [warped_details_top_left + all_scores_offset , all_scores_size];
all_scores_roi(:,1:2) = all_scores_roi(:,1:2) - numAdditionalPixels;
all_scores_roi(:,3:4) = all_scores_roi(:,3:4) + 2*numAdditionalPixels;

img_all_scores = imcrop(warpedImg, all_scores_roi);
Icorrected_all_scores = imtophat(img_all_scores, strel("disk",15));
BW_all_scores = imbinarize(rgb2gray(Icorrected_all_scores));

figure
montage({img_all_scores, Icorrected_all_scores, BW_all_scores}, "BorderSize", 3, "BackgroundColor", "red");

marker_all_scores = imerode(Icorrected_all_scores, strel("line",10,0));
Iclean_all_scores = imreconstruct(marker_all_scores, Icorrected_all_scores);
Ibinary_all_scores = imbinarize(Iclean_all_scores);

figure
montage({Iclean_all_scores, Ibinary_all_scores, marker_all_scores});

BW2_all_scores = imcomplement(BW_all_scores);
figure
imshowpair(Ibinary_all_scores, BW2_all_scores, "montage");

results_all_scores = ocr(BW2_all_scores, LayoutAnalysis="page", CharacterSet="0123456789")

%% MAIN IMPL STOP HERE
disp("done")

%% Ocr on score ROI
img_cropped = imcrop(img, score_roi);
Icorrected = imtophat(img_cropped,strel("disk",15));
BW1 = imbinarize(Icorrected);

figure 
imshowpair(img_cropped,BW1,"montage")

% Perform morphological reconstruction and show binarized image.
marker = imerode(Icorrected,strel("line",10,0));
Iclean = imreconstruct(marker,Icorrected);

Ibinary = imbinarize(Iclean);

figure
montage({Iclean,Ibinary,marker})

BW2 = imcomplement(Ibinary);
figure
imshowpair(Ibinary,BW2,"montage")


results = ocr(BW2,LayoutAnalysis="none");
score = string(strip(replace({results.Text}, {newline, ',', '.'}, "")));
score = str2num(score)

%% OCR on difficulty ROI
img_cropped = imcrop(img, difficulty_roi);

figure
imshowHist(img_cropped);

% thresholding
I = rgb2hsv(img_cropped);
% Just thresholding Value
channel3Min = 0.63;
channel3Max = 1.000;

% Create mask based on chosen histogram thresholds
sliderBW = (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW1 = sliderBW;
BW3 = imcomplement(BW1);

masked_img_cropped = img_cropped;

% Set background pixels where BW is false to zero.
masked_img_cropped(repmat(~BW,[1 1 3])) = 0;

figure
imshowHist(masked_img_cropped);



figure
montage({img_cropped, BW1, BW3});

results = ocr(BW3,LayoutAnalysis="block"); % Block is better here since there is a very likely chance theres a lot of stuff on the outside 
difficulty = string(strip(replace({results.Text}, {newline}, "")))

%% ROI MANUAL selection
figure;
imshow(img);
roi = drawrectangle; % same as imrect but a reference and live
roiPos = roi.Position; % [xmin, ymin, width, height]
roiPos = round(roiPos);
img_cropped = img(roiPos(2) + (0:roiPos(4)), roiPos(1) + (0:roiPos(3))); %% This only extracts B&W
img_cropped = imcrop(img, roiPos);

figure
imshow(img_cropped)
%% Draw
figure
Iout = insertShape(grayImg,"rectangle",roiPos,LineWidth=4);
BW = imbinarize(grayImg);
imshowpair(Iout, BW, 'montage')

%% Fucky math for details text (black text white bg)
Icorrected = imbothat(img_cropped,strel("disk",15));
%Icorrected = imtophat(img_cropped,strel("disk",15));

% gaus filter to reduce LED screen noise
Ifiltered = imgaussfilt(Icorrected, 1);
BW = rgb2gray(Ifiltered);

BW1 = imbinarize(BW);

% morphological filtering (no reconstruction as some letters are non
% contiguous)
BW2 = bwareaopen(BW1, 5);

% Black text on white background preferred for OCR
BW3 = imcomplement(BW2);

figure 
montage({img_cropped, BW2, BW1, BW3});

results = ocr(BW3,LayoutAnalysis="block"); % Block is better here since there is a very likely chance theres a lot of stuff on the outside 
results.Text

%% Fucky math for numbers text
% Remove keypad background.
%Icorrected = imbothat(img_cropped,strel("disk",15));
Icorrected = imtophat(img_cropped,strel("disk",15));

BW1 = imbinarize(Icorrected);

figure 
imshowpair(img_cropped,BW1,"montage")

% Perform morphological reconstruction and show binarized image.
marker = imerode(Icorrected,strel("line",10,0));
Iclean = imreconstruct(marker,Icorrected);

Ibinary = imbinarize(Iclean);

figure
montage({Iclean,Ibinary,marker})

BW2 = imcomplement(Ibinary);
figure
imshowpair(Ibinary,BW2,"montage")

results = ocr(BW2,LayoutAnalysis="none"); % This is good if detecting JUST single number as seen here
%https://au.mathworks.com/help/vision/ug/recognize-text-using-optical-character-recognition-ocr.html 
% https://www.youtube.com/watch?v=BL9eP8qniwg
results.Text


%% FUcky math for difficulty text

% thresholding

I = rgb2hsv(img_cropped);
% Just thresholding Value
channel3Min = 0.63;
channel3Max = 1.000;

% Create mask based on chosen histogram thresholds
sliderBW = (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW1 = sliderBW;

% Alternative binarization/ auto thresholding
I2 = rgb2gray(img_cropped);
BW2 = imbinarize(I2);

figure
montage({img_cropped, BW1, BW2});

BW3 = imcomplement(BW1);

results = ocr(BW3,LayoutAnalysis="block"); % Block is better here since there is a very likely chance theres a lot of stuff on the outside 
results.Text

%% OCR

ocrResults = ocr(img,roiPos)



%% OCR on numbers
ocrResults = ocr(grayImg,roiPos, "CharacterSet", "0123456789", "LayoutAnalysis","block")

%% Boundary segregation stuff
I = imread('rice.png'); % This image is built in
imshow(I)
BW = imbinarize(I);
[B,L] = bwboundaries(BW,'noholes'); % This also has the same number as conncomp
imshow(label2rgb(L, @jet, [.5 .5 .5]))


CC = bwconncomp(BW);
auto_stats = regionprops(BW);
% So basically regionprops with no CC provided manually just uses bwconncomp under the hood
manual_stats = regionprops(CC);


%% Get HRECT(tx, ty, w, h) whcih is different from roi (corner verteces)
figure;
imshow(img);
h_rect = imrect();
% Rectangle position is given as [xmin, ymin, width, height]
pos_rect = h_rect.getPosition();
% Round off so the coordinates can be used as indices
pos_rect = round(pos_rect);
% Select part of the image
img_cropped = img(pos_rect(2) + (0:pos_rect(4)), pos_rect(1) + (0:pos_rect(3)));

%% Pure OCR for gits and shiggles
results = ocr(img);

%% Image boundary
% Convert to grayscale if needed
gray = rgb2gray(img);

% Threshold to binary (adjust threshold value if needed)
bw = gray < 50;  % Black regions become white (1), rest becomes black (0)

% Clean up noise
bw = imclose(bw, strel('disk', 5));
bw = imfill(bw, 'holes');

% Find connected components
cc = bwconncomp(bw);
stats = regionprops(cc, 'Area', 'BoundingBox');


%% Full OCR with some processing for score


%% Hough lines
grayImg = rgb2gray(img_cropped);

BW = edge(grayImg,'canny');
[H,theta,rho] = hough(BW);
P = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
lines = houghlines(BW,theta,rho,P,'FillGap',5,'MinLength',7);
figure, imshow(grayImg), hold on
max_len = 0;
for k = 1:length(lines)
   xy = [lines(k).point1; lines(k).point2];
   plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');

   % Plot beginnings and ends of lines
   plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
   plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');

   % Determine the endpoints of the longest line segment
   len = norm(lines(k).point1 - lines(k).point2);
   if ( len > max_len)
      max_len = len;
      xy_long = xy;
   end
end
% highlight the longest line segment
plot(xy_long(:,1),xy_long(:,2),'LineWidth',2,'Color','red');

%% Contours and getting accurate details rect
[B,L] = bwboundaries(BW4,'noholes');

coinNumber = 1;
boundary = B{coinNumber};

figure

imshow(img)
hold on
visboundaries({boundary})
hold off

%% Colour histogram 
% Convert to HSV color space
hsv_img = rgb2hsv(img_cropped);

% Extract the hue channel (first channel)
r = hsv_img(:,:,1);

% Flatten the hue matrix to a vector
hue_vector = r(:);

% Create histogram with specified number of bins
num_bins = 36; % 36 bins = 10 degrees per bin
figure;
histogram(hue_vector, num_bins, 'EdgeColor', 'none');

% Customize the plot
xlabel('Hue Value (0-1, where 0=Red, 0.33=Green, 0.67=Blue)');
ylabel('Pixel Count');
title('Hue Distribution Histogram');
grid on;

% Add color bar showing hue spectrum
colormap(hsv(num_bins));
colorbar('Ticks', linspace(0, 1, 7), ...
         'TickLabels', {'Red', 'Yellow', 'Green', 'Cyan', 'Blue', 'Magenta', 'Red'});

% Optional: Find the most dominant hue
[counts, edges] = histcounts(hue_vector, num_bins);
[max_count, max_idx] = max(counts);
dominant_hue = (edges(max_idx) + edges(max_idx+1)) / 2;

fprintf('Most dominant hue value: %.3f\n', dominant_hue);


%% Moire filtering
img = imread('moire_img.png');


[rows, cols, ~] = size(img);

% Normalization weights
x = abs((0:cols-1) - cols/2).^0.5;
y = abs((0:rows-1) - rows/2).^0.5;
coefs = max((x + y').^2, 0.01);


workspace;  % Make sure the workspace panel is showing.
format long g;
format compact;

hsv_img = rgb2hsv(img);

% Extract individual channels
r = img(:,:,1);
g = img(:,:,2);
b = img(:,:,3);

% ONLY do this for channel splitting freq domain impl for hsv, remember to change img back for visualisation
% r = hsv_img(:,:,1);
% g = hsv_img(:,:,2);
% b = hsv_img(:,:,3);


figure
imshow(img);

threshold = 10;

% Compute the 2D fft for red channel
frequencyImage_r = fftshift(fft2(r));
% Take log magnitude so we can see it better in the display.
amplitudeImage = log(abs(frequencyImage_r));
spectrum = 20 * log(abs(frequencyImage_r) .* coefs);

threshImage = spectrum > threshold;
minValue = min(min(spectrum));
maxValue = max(max(spectrum));

figure
imshow(threshImage, [minValue maxValue])


minValue = min(min(amplitudeImage))
maxValue = max(max(amplitudeImage))
figure
imshow(amplitudeImage, []);

%% Mask creation
top_left_mask = [399 551];  % Measured from imshow
mask_radius = 150;
s = size(r);

% Calculate center and offsets from the measured top-left position
center_x = s(2) / 2;
center_y = s(1) / 2;
offset_x = center_x - top_left_mask(1);
offset_y = center_y - top_left_mask(2);

% Create four corners symmetrically around the center using the measured top-left
%top_right_mask = [center_x + offset_x, center_y - offset_y];
%bottom_left_mask = [center_x - offset_x, center_y + offset_y];
top_right_mask= [787 535];
bottom_left_mask = [414	1068];
%bottom_right_mask = [center_x + offset_x, center_y + offset_y];
bottom_right_mask = [802 1053];
%mask = circles2mask([top_left_mask; top_right_mask; bottom_left_mask; bottom_right_mask], mask_radius, s);

mask = circles2mask([center_x center_y], mask_radius, s); % Ideal filter for including JUST the center
mask = ~mask;

figure 
imshow(mask)

% Apply mask to all three channels
freq_image_masked_r = frequencyImage_r;
freq_image_masked_r(mask) = 0;

frequencyImage_g = fftshift(fft2(g));
freq_image_masked_g = frequencyImage_g;
freq_image_masked_g(mask) = 0;

frequencyImage_b = fftshift(fft2(b));
freq_image_masked_b = frequencyImage_b;
freq_image_masked_b(mask) = 0;

amplitudeImage2 = log(abs(freq_image_masked_r));

figure 
imshow(amplitudeImage2, [minValue maxValue]);

% Inverse transform all channels
filteredImage_r = ifft2(ifftshift(freq_image_masked_r));
filteredImage_r = real(filteredImage_r);
filteredImage_r = mat2gray(filteredImage_r);

filteredImage_g = ifft2(ifftshift(freq_image_masked_g));
filteredImage_g = real(filteredImage_g);
filteredImage_g = mat2gray(filteredImage_g);

filteredImage_b = ifft2(ifftshift(freq_image_masked_b));
filteredImage_b = real(filteredImage_b);
filteredImage_b = mat2gray(filteredImage_b);

% Combine channels back into RGB image
filteredImage_rgb = cat(3, filteredImage_r, filteredImage_g, filteredImage_b);

%filteredImage_rgb = hsv2rgb(filteredImage_rgb); % iF the rgb channels were actually hsv

figure 
imshow(filteredImage_rgb)

%% Gaussian filter using Fourier Transform
% Convert image to grayscale
img_gray = rgb2gray(img);

% Compute FFT
fft_img = fftshift(fft2(img_gray));

% Get image dimensions
[rows, cols] = size(img_gray);

% Create Gaussian kernel in frequency domain
sigma = 30;  % Standard deviation - controls filter bandwidth
[x, y] = meshgrid(-cols/2:cols/2-1, -rows/2:rows/2-1);
% https://www.geeksforgeeks.org/machine-learning/gaussian-kernel/
gaussian_mask = exp(-(x.^2 + y.^2) / (2 * sigma^2));

figure 
mesh(gaussian_mask)

% Normalize Gaussian kernel
gaussian_mask = gaussian_mask / max(gaussian_mask(:));

% Apply Gaussian filter in frequency domain
fft_filtered = fft_img .* gaussian_mask;

% Inverse FFT
img_filtered = ifft2(ifftshift(fft_filtered));
img_filtered = real(img_filtered);
img_filtered = mat2gray(img_filtered);

% Display results
figure
subplot(2, 2, 1)
imshow(img_gray)
title('Original Image')

subplot(2, 2, 2)
imshow(log(abs(fft_img) + 1), [])
title('FFT - Original Image')

subplot(2, 2, 3)
imshow(gaussian_mask)
title('Gaussian mask (Frequency Domain)')

subplot(2, 2, 4)
imshow(img_filtered)
title('Gaussian Filtered Image')


%% fitlering normally

% TODO Try filter2
% https://au.mathworks.com/matlabcentral/answers/269905-how-to-apply-a-2d-low-pass-filter-to-a-colored-image
% or conv2
% https://au.mathworks.com/matlabcentral/answers/75881-how-i-can-implement-lowpass-filter-on-image-using-matlab

A = zeros(10);
A(3:7,3:7) = ones(5);
mesh(A) % this shows a meshplot

filtered = imgaussfilt(img, 100, "FilterSize",5);
figure 
imshow(filtered)

%% Fitlering image with gaussian and doing rest of roi morphology

% Note: this works actually relatively well for moire noise especially the
% median filtering. 

Ifiltered = filteredImage_rgb; % This is result from previous 

%Ifiltered = img; 

Ifiltered = imgaussfilt(Ifiltered, 1.5);

medfilt_window = [15, 15];

% Apply medfilt2 to each RGB channel separately
r_filtered = medfilt2(Ifiltered(:,:,1), medfilt_window);
g_filtered = medfilt2(Ifiltered(:,:,2), medfilt_window);
b_filtered = medfilt2(Ifiltered(:,:,3), medfilt_window);

% Combine filtered channels back into RGB image
Ifiltered = cat(3, r_filtered, g_filtered, b_filtered);


% Create better mask with LAB (more expensive)
% Convert RGB image to chosen color space
I = rgb2lab(Ifiltered);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 50.000;
channel1Max = 100.000;

% Define thresholds for channel 2 based on histogram settings
channel2Min = -61.360;
channel2Max = -17.210;

% Define thresholds for channel 3 based on histogram settings
channel3Min = -31.648;
channel3Max = 34.659;

% Create mask based on chosen histogram thresholds
sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW = sliderBW;

%BW = BW_HSV; % Force select HSV instead 
figure
montage({Ifiltered, BW})
 

% Do blob detection and filter small blobs
figure
[B,L] = bwboundaries(BW,'noholes');
imshow(label2rgb(L, @jet, [.5 .5 .5]))

figure 
imshow(BW);
hold on;
BW2 = bwareafilt(BW, [3000, 50000]); %Filter out overly small and large blobs
% ABove might not be necessary with imopen

m = 360; n = 90;

SE_open = strel("rectangle", round([n m] .* 0.1));
% The open operation makes us lose our angle so we have to be mindful of that
% On second thought angle is not needed, use phone gyro
BW3 = imopen(BW2, SE_open); 

SE_close = strel("rectangle", round([n m] .* 1.1));
BW4 = imclose(BW3, SE_close);

figure;
montage({BW2, BW3, BW4}, "Size", [1 3], "BorderSize", 3, "BackgroundColor", "red");

CC = bwconncomp(BW4);
stats = regionprops(CC, ["BoundingBox"] );
roi = vertcat(stats(:).BoundingBox);

figure
L4 = labelmatrix(CC);
RGB_label = label2rgb(L4,@copper,"c","shuffle");
imshow(RGB_label)

numAdditionalPixels = 5;
roi(:,1:2) = roi(:,1:2) - numAdditionalPixels;
roi(:,3:4) = roi(:,3:4) + 2*numAdditionalPixels;

roi_img = insertShape(img,"rectangle",roi,LineWidth=4);

figure 
imshow(roi_img)

%% Ideal low pass filter

size_img = 512;
cutoff_radius = 50;  % adjust this to change cutoff frequency

% Create frequency grid
[X, Y] = meshgrid(1:size_img, 1:size_img);
center = size_img/2 + 1;

% Distance from center
D = sqrt((X - center).^2 + (Y - center).^2);

% Harsh circular cutoff - disc in frequency domain
H_freq = double(D <= cutoff_radius);

% Convert to spatial domain (this is the convolution kernel)
h_spatial = ifft2(ifftshift(H_freq));
h_spatial = real(fftshift(h_spatial));

% Display
figure;
subplot(1,2,1);
imshow(H_freq, []);
title('Ideal Low-Pass Filter (Frequency Domain)');

subplot(1,2,2);
imshow(h_spatial(200:313, 200:313), []);
title('Jinc Function Kernel (Spatial Domain)');

% 3D view of the jinc kernel
figure;
surf(h_spatial(200:313, 200:313));
shading interp;
title('3D View of Jinc Kernel');
xlabel('X');
ylabel('Y');
zlabel('Amplitude');


%% Descreen algo (Eeeh doesnt work that ell)
% Based oon https://github.com/6o6o/fft-descreen/tree/master



% FFT-based descreen filter for LCD moire removal
img = double(img);

[rows, cols, ~] = size(img);

% Normalization weights
x = abs((0:cols-1) - cols/2).^0.5;
y = abs((0:rows-1) - rows/2).^0.5;
coefs = max((x + y').^2, 0.01);

% Middle preservation ellipse
mid = 8;
ew = floor(cols/mid);
eh = floor(rows/mid);
[X, Y] = meshgrid(-ew:ew, -eh:eh);
ellipse_mid = double((X/ew).^2 + (Y/eh).^2 <= 1);
middle = zeros(rows, cols);
pw = floor((cols - ew*2)/2);
ph = floor((rows - eh*2)/2);
middle(ph+1:ph+size(ellipse_mid,1), pw+1:pw+size(ellipse_mid,2)) = ellipse_mid;

% Dilation kernel
rad = 6;
[X, Y] = meshgrid(-rad:rad, -rad:rad);
kernel = double((X/rad).^2 + (Y/rad).^2 <= 1);

% Process each channel
for i = 1:3
    % FFT
    fftimg = fft2(img(:,:,i));
    fftimg = fftshift(fftimg);
    
    % Magnitude spectrum
    spectrum = 20 * log(abs(fftimg) .* coefs);
    
    % Threshold
    threshold = 92;
    thresh = double(max(0, spectrum) > threshold);
    thresh = thresh .* (1 - middle);
    
    % Dilate
    thresh = imdilate(thresh, kernel);
    
    % Gaussian blur
    thresh = imgaussfilt(thresh, rad/3);
    
    % Apply mask
    thresh = 1 - thresh;
    fftimg = fftimg .* thresh;
    
    % Inverse FFT
    fftimg = ifftshift(fftimg);
    out_img(:,:,i) = abs(ifft2(fftimg));
end

figure 
imshow(fftimg)

figure
imshow(out_img)