function [] = imshowHist(rgbImage)
hsvImage = rgb2hsv(rgbImage);
hImage = hsvImage(:, :, 1);
sImage = hsvImage(:, :, 2);
vImage = hsvImage(:, :, 3);
subplot(2,2,1);
hHist = histogram(hImage);
grid on;
title('Hue Histogram');
subplot(2,2,2);
sHist = histogram(sImage);
grid on;
title('Saturation Histogram');
subplot(2,2,3);
vHist = histogram(vImage);
grid on;
title('Value Histogram');
subplot(2,2,4);
imshow(rgbImage);
end