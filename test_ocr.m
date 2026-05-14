clear; close all;

%img = imread('details_ocr_input_8.jpg');
img = imread('ocr_input_marvelous_line_2.png');
figure;
imshow(img)
results = ocr(img, LayoutAnalysis="none", CharacterSet='0123456789,.');
%results = ocr(img, LayoutAnalysis="none");
results
