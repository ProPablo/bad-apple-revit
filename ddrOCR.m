%% INIT
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

%img = imrotate(img, angle);
figure 
imshow(img)

%% Selecting Details box

% Convert to HSV for better color detection

% Create mask of JUST details
% Convert RGB image to chosen color space
I = rgb2hsv(img);
  
% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.427;
channel1Max = 0.531;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.204;
channel2Max = 1.000;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.592;
channel3Max = 1.000;

% Create mask based on chosen histogram thresholds
sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW = sliderBW;
figure
imshowpair(grayImg, BW, 'montage')


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
% The open operation makes us lose our angle so we have to be mindful of that
% On second thought angle is not needed, use phone gyro
BW3 = imopen(BW2, SE_open); 

SE_close = strel("rectangle",[n m] .* 1.2);
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
correct_roi = correct_roi(2, :); % Only need first detection

%% Create offsets for score OCR
% Again thise are values based on ocr_test_2 
% values will have to be normalized into UV coords relative to details top
% right and width and height of details box

% Raw offsets
top_left_details = [2054,2345];
bot_right_details = [2417,2454];

top_left_score = [2720 2551];
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

%% Ocr on score ROI`1   7
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
% thresholding
I = rgb2hsv(img_cropped);
% Just thresholding Value
channel3Min = 0.63;
channel3Max = 1.000;

% Create mask based on chosen histogram thresholds
sliderBW = (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW1 = sliderBW;
BW3 = imcomplement(BW1);

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
[~, idx] = max([stats.Area]);
boundary = stats(idx).ConvexHull;  % Nx2 matrix of boundary points


% Approximate polygon (Douglas-Peucker algorithm)
perimeter = stats(idx).Perimeter;
epsilon = 0.1;
approx = reducepoly(boundary, epsilon);

% Dr aw approximated polygon with different color for each edge
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

%% Perform homography according to details reference points from ocr_test_2

% Create the 4 reference corner points
ref_tl = top_left_details;
ref_tr = [bot_right_details(1), top_left_details(2)];
ref_br = bot_right_details;
ref_bl = [top_left_details(1), bot_right_details(2)];

% Reference points in same order as your detected corners
referencePoints = [ref_tl; ref_tr; ref_br; ref_bl];

% Your detected corners from the image
ordered = [tl; tr; br; bl];

% Compute homography
tform = fitgeotrans(ordered, referencePoints, 'projective');

% Apply perspective transform
outputImg = imwarp(img, tform);

figure 
montage({img, outputImg})

%% Read from offsets