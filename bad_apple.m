%% bad apple
bad_img = imread('bad/0003.png');

gray_img = rgb2gray(bad_img);
BW = imbinarize(gray_img, 'global'); % we dont need adaptive here, adaptive is good for eg a half lit page
edges = edge(BW);
[y, x] = find(edges == 1); % find gives row, cols
figure;
plot(y,x)
figure;
imshowpair(bad_img,BW,'montage')

figure;
scatter(y,-x)
