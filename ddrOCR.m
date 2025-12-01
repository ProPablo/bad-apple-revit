%% INIT
img = imread('ocr_test_2.jpg');
imshow(img)
% line = drawline;
grayImg = rgb2gray(img);

%% Manually get angle
linePos = [[0.5	1113.5];
[3024.5	1053.5]];
y1 = linePos(1, 2);
y2 = linePos(2, 2);

x1 = linePos(1, 1);
x2 = linePos(2, 1);

angle = rad2deg( atan2(y2 - y1, x2 - x1));


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

%% Perform some morphology
m = 360; n = 90;
SE_open = strel("rectangle",[n m] .* 0.1);
BW3 = imopen(BW2, SE_open); % The open operation makes us lose our angle so we have to be mindful of that
SE_close = strel("rectangle",[n m] .* 1.2);
BW4 = imclose(BW3, SE_close);
figure;
montage({BW2, BW3, BW4}, "Size", [1 3], "BorderSize", 3, "BackgroundColor", "red");

CC = bwconncomp(BW2);

figure
L4 = labelmatrix(CC);
RGB_label = label2rgb(L4,@copper,"c","shuffle");
imshow(RGB_label)


% run ocr on each blob


% Filter to only get the blob with 'details'

% 





%% ROI MANUAL selection
figure;
imshow(img);
roi = drawrectangle; % same as imrect but a reference and live
roiPos = roi.Position; % [xmin, ymin, width, height]
roiPos = round(roiPos);
img_cropped = img(roiPos(2) + (0:roiPos(4)), roiPos(1) + (0:roiPos(3)));
figure
imshow(img_cropped)
%% Draw
figure
Iout = insertShape(grayImg,"rectangle",roiPos,LineWidth=4);
BW = imbinarize(grayImg);
imshowpair(Iout, BW, 'montage')

%% Get just manual image



%% Fucky math
% Remove keypad background.
Icorrected = imtophat(img_cropped,strel("disk",15));

BW1 = imbinarize(Icorrected);

figure 
imshowpair(img_cropped,BW1,"montage")

% Perform morphological reconstruction and show binarized image.
marker = imerode(Icorrected,strel("line",10,0));
Iclean = imreconstruct(marker,Icorrected);

Ibinary = imbinarize(Iclean);

figure
imshowpair(Iclean,Ibinary,"montage")

BW2 = imcomplement(Ibinary);
figure
imshowpair(Ibinary,BW2,"montage")

results = ocr(BW2,LayoutAnalysis="none"); % This is good if detecting JUST single number as seen here
%https://au.mathworks.com/help/vision/ug/recognize-text-using-optical-character-recognition-ocr.html 
% https://www.youtube.com/watch?v=BL9eP8qniwg
results.Text
% TODO Fix for details text detection

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