%% bad apple
bad_img = imread('bad/0004.png');

gray_img = rgb2gray(bad_img);
BW = imbinarize(gray_img, 'global'); % we dont need adaptive here, adaptive is good for eg a half lit page
BW2 = imcomplement(BW); % invert selection

figure;
montage({bad_img,BW,BW2});

[B,L, n] = bwboundaries(BW2);

figure
imshow(label2rgb(L, @jet, [.5 .5 .5]))
hold on

num_frames = 2;

simple_bounds = cell(length(B), num_frames);
centroids = cell(length(B), num_frames);

for k = 1:length(B)
   boundary = B{k};
   plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
   
   % By default bwboundaries provides coords in y, x
   ps = polyshape(boundary(:,2), boundary(:,1));
   %This xy is correct
   [x,y] = centroid(ps);

   plot(x,y,'r*')
   %Simplify boundary
   simplified = downsample(boundary, 4);
   simplified = simplified(:, [2, 1]) .* [1, -1]; % Convert to (x, y) and flip y (TODO this does flip but makes y negative)
   
   simple_bounds{1, k} = simplified; 
   centroids{1, k} = [x,-y];
end

save('bad_apple.mat', 'simple_bounds', "num_frames", "centroids");


%% Edge detection

edges = edge(BW2);
[y, x] = find(edges == 1); % find gives row, cols
figure;
plot(y,x)


figure;
scatter(x,-y)

%% create boundaries without edge detection
[B1,L1, n1] = bwboundaries(BW2, 'noholes');

figure
imshow(label2rgb(L1, @jet, [.5 .5 .5]))
hold on
for k = 1:length(B1)
   boundary = B1{k};
   plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
end

%% with edge detection
[B,L, n] = bwboundaries(edges, 'noholes'); % n here is still same but for some reason L (contiguous regions) is all 1 colour

figure
imshow(label2rgb(L, @jet, [.5 .5 .5]))
hold on
for k = 1:length(B)
   boundary = B{k};

   plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
end

%% Simplify the biggest region
[B,L, n] = bwboundaries(BW2, 'noholes');
lengths = [];
for k = 1:length(B)
   lengths = [lengths, length(B{k})];
end
[~, idx] = max(lengths);
biggest = B{idx};

% Downsample the biggest boundary
downsampled = resample(biggest, 1, 4);

% Plot both
figure
plot(biggest(:,2), -biggest(:,1), 'b-', 'LineWidth', 1.5)
hold on
plot(downsampled(:,2), -downsampled(:,1), 'r-', 'LineWidth', 2)
legend('Original', 'Downsampled')
axis equal

%% Simplify using downsample
% Downsample the biggest boundary
downsampled = downsample(biggest, 4);

% Plot both
figure
plot(biggest(:,2), -biggest(:,1), 'b-', 'LineWidth', 1.5)
hold on
plot(downsampled(:,2), -downsampled(:,1), 'r-', 'LineWidth', 2)
legend('Original', 'Downsampled')
axis equal

%% Need closed shapes and countours instead
CC = bwconncomp(BW2);
stats = regionprops(CC, "all");

% Find the largest area
areas = [stats.Area];
[~, idx_largest] = max(areas);
largest = stats(idx_largest);

% Plot the contour of the largest region
figure
imshow(bad_img)
hold on
boundary_largest = largest.PixelList;
plot(boundary_largest(:,1), boundary_largest(:,2), 'r-', 'LineWidth', 2) % Kinda doodoo
title('Largest Region Contour')



%% Non pixels version (convex hull)
boundary = stats(idx_largest).ConvexHull;

figure
imshow(bad_img)
hold on
plot(boundary(:,1), boundary(:,2), 'r-', 'LineWidth', 2)
title('Convex Hull of Largest Region')

%% Compare downsampling methods
boundary = biggest;

% Method 1: Simple downsample (can be jaggy) (does the same thing as
% dowsample command)
factor = 10;
boundary_downsampled = boundary(1:factor:end, :);

% Method 2: Interpolation (smoother)
x = boundary(:, 2);
y = boundary(:, 1);
t = 1:length(x);
t_new = linspace(1, length(x), round(length(x)/factor));
x_interp = interp1(t, x, t_new);
y_interp = interp1(t, y, t_new);
boundary_interpolated = [y_interp', x_interp'];

% Visualize comparison
figure;
hold on;
title('Downsampled');
plot(boundary(:,2), -boundary(:,1), 'b-', 'LineWidth', 5)
plot(boundary_downsampled(:,2), -boundary_downsampled(:,1), 'r-', 'LineWidth', 2)
plot(boundary_interpolated(:,2), -boundary_interpolated(:,1), 'y-', 'LineWidth', 2)
legend('Original', 'Downsampled', 'Interpolated')
axis equal;