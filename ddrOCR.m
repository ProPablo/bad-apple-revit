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
hsvImg = rgb2hsv(img);

% Create mask of JUST details
% Convert RGB image to chosen color space
I = rgb2hsv(RGB);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.458;
channel1Max = 0.547;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.405;
channel2Max = 1.000;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.782;
channel3Max = 1.000;

% Create mask based on chosen histogram thresholds
sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW = sliderBW;

% Do blob detection and filter small blobs

% run ocr on each blob

% Filter to only get the blob with 'details'

% 



imshowpair(grayImg, hsvImg, 'montage')


%% ROI MANUAL selection
figure;
imshow(img);
roi = drawrectangle;
roiPos = roi.Position;
%% Draw
figure
Iout = insertShape(grayImg,"rectangle",roiPos,LineWidth=4);
BW = imbinarize(grayImg);
imshowpair(Iout, BW, 'montage')

%% Get just manual image



%% Fucky math
% Remove keypad background.
Icorrected = imtophat(grayImg,strel("disk",15));

BW1 = imbinarize(Icorrected);

figure 
imshowpair(I,BW1,"montage")

% Perform morphological reconstruction and show binarized image.
marker = imerode(Icorrected,strel("line",10,0));
Iclean = imreconstruct(marker,Icorrected);

Ibinary = imbinarize(Iclean);

figure
imshowpair(Iclean,Ibinary,"montage")

BW2 = imcomplement(Ibinary);
figure
imshowpair(Ibinary,BW2,"montage")

results = ocr(BW2,LayoutAnalysis="block");

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

