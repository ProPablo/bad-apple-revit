%% bad apple
clear; close all;

% shoutout to mxb161 for dis
bad_vid = VideoReader('bad-apple.mp4')

APPROX_BOUNDARY_AMOUNT = 5;
MIN_SIMPLIFIED_POINTS = 4;

%num_frames = bad_vid.NumFrames;
%start_frame = 0;

num_frames = 2000;
start_frame = 0;


simple_bounds = cell(num_frames, APPROX_BOUNDARY_AMOUNT);
centroids = cell(num_frames, APPROX_BOUNDARY_AMOUNT);
boundary_nums = zeros(1, num_frames);

figure

v = VideoWriter('regions_vid.mp4', 'MPEG-4');
v.FrameRate = 30;
open(v);

for i=1:num_frames
   frame = read(bad_vid, i + start_frame);
   gray_img = rgb2gray(frame);
   BW = imbinarize(gray_img, 'global'); % we dont need adaptive here, adaptive is good for eg a half lit page
   BW2 = imcomplement(BW); % invert selection
   
   se = strel('disk', 1); % merge very close eedges so we dont get sub regions in ps
   BW3 = imopen(BW2, se);
   
   [B,L, n, A] = bwboundaries(BW3);
   boundary_num = 0;
   
   regions_img = label2rgb(L, @jet, [.5 .5 .5]);
   imshow(regions_img)
   hold on
   writeVideo(v, regions_img);

   for k = 1:length(B)

      boundary = B{k};
      plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
      if (sum(A(k, :)) == 0) %isparent
         boundary = downsample(boundary, 2);
         ps = polyshape(boundary(:,2), boundary(:,1));
         ps_size = size(ps.Vertices);
         if (ps.NumRegions == 0)
            continue
         end
         if (ps_size <= MIN_SIMPLIFIED_POINTS)
            continue
         end
         ps = polybuffer(ps, 0.5, "JointType","square");
         ps = simplify(ps, "KeepCollinearPoints",false); % pre sure this is doing nothing but just in case
         ps = sortregions(ps,'perimeter','descend');
         regs = regions(ps);
         ps = regs(1);
         [x,y] = centroid(ps);

         children_idx = find(A(:, k) == 1);
         % Add children (holes)
         for j = 1:length(children_idx)
            child_idx = children_idx(j);
            % child preprocessing
            child_boundary = B{child_idx};
            child_boundary = downsample(child_boundary, 2);
            child_ps = polyshape(child_boundary(:,2), child_boundary(:,1));

            child_ps = polybuffer(child_ps, 0.5, "JointType","square");
            child_ps = simplify(child_ps, "KeepCollinearPoints",false);

            child_ps_size = size(child_ps.Vertices);

            if (child_ps.NumRegions == 0 | child_ps_size < MIN_SIMPLIFIED_POINTS)
               continue
            end
            ps = xor(ps, child_ps);

         end

         simplified = ps.Vertices .* [1, -1];

         boundary_num = boundary_num + 1;
         simple_bounds{i, boundary_num} = simplified;
         centroids{i, boundary_num} = [x,-y];

      end

   end
   boundary_nums(i) = boundary_num;
   drawnow;
%pause(0.1)
end
close(v);

save('bad_apple.mat', 'simple_bounds', "num_frames", "centroids", "boundary_nums");

%% bad apple video lower framerate
bad_vid = VideoReader('bad-apple.mp4')

desired_framerate = 10;
record_per_frame = floor(bad_vid.FrameRate/ desired_framerate);

single_frame = read(bad_vid, 100);
f = figure('visible', true);

lower_fps_vid = VideoWriter('low_fps_bad_apple')
lower_fps_vid.FrameRate = 10;
open(lower_fps_vid)

for i=1:record_per_frame:bad_vid.NumFrames
   % Read the next frame
   frame = read(bad_vid, i);
   % Show the mask

   writeVideo(lower_fps_vid, frame)
   imshow(frame)
end

close(lower_fps_vid);
%imshow(single_frame);

%% Read imgs into a video
imgFolder = 'imgs';

files = dir(fullfile(imgFolder, '*.jpg'));

v = VideoWriter('output.mp4', 'MPEG-4');
v.FrameRate = 30;
open(v);

for i = 1:length(files)
    img = imread(fullfile(imgFolder, files(i).name));
    writeVideo(v, img);
end

close(v);

%% bad apple single frame read
%bad_img = imread('bad/0004.png');
%bad_img = imread('bad/0025.png');
%bad_img = imread('bad/0058.png'); % Curve length is too small for Revit's tolerance (as identified by Application.ShortCurveTolerance).
%bad_img = read(bad_vid, 1884);
%bad_img = read(bad_vid, 1878);
bad_img = read(bad_vid, 551);
% start and end points are the same here


gray_img = rgb2gray(bad_img);
BW = imbinarize(gray_img, 'global'); % we dont need adaptive here, adaptive is good for eg a half lit page
BW2 = imcomplement(BW); % invert selection

se = strel('disk', 1); % merge very close eedges so we dont get sub regions in ps
BW2 = imopen(BW2, se);

figure;
montage({bad_img,BW,BW2});

[B,L, n, A] = bwboundaries(BW2);

figure
imshow(label2rgb(L, @jet, [.5 .5 .5]))
hold on

% Plot boundaries and add labels at centroids
for k = 1:length(B)
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
    
    % Calculate centroid
    centroid_x = mean(boundary(:,2));
    centroid_y = mean(boundary(:,1));
    
    % Add text label
    text(centroid_x, centroid_y, num2str(k), ...
        'Color', 'white', ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', 'black', ...
        'EdgeColor', 'white', ...
        'Margin', 2)
end


%% simplified with polyshape only output

figure
hold on

num_frames = 2;

MIN_SIMPLIFIED_POINTS = 4;

simple_bounds = cell(num_frames, length(B));
centroids = cell(num_frames, length(B));
boundary_nums = zeros(1, num_frames);


boundary_num = 0;

for k = 1:length(B)

   boundary = B{k};
   plot(boundary(:,2), boundary(:,1), 'b', 'LineWidth', 2)
   if (sum(A(k, :)) == 0) %isparent
      boundary = downsample(boundary, 2);
      % By default bwboundaries provides coords in y, x
      ps = polyshape(boundary(:,2), boundary(:,1))
      ps = rmslivers(ps,1); 
      
      %Sometimes you get sub regions TODO determine if we need to use because
      %ps by default splits verteces by NaNs
        ps_size = size(ps.Vertices);
         if (ps.NumRegions == 0)
            continue
         end
         if (ps_size <= MIN_SIMPLIFIED_POINTS)
            continue
         end

      ps = polybuffer(ps, 0.5, "JointType","square");
      ps = simplify(ps, "KeepCollinearPoints",false); % pre sure this is doing nothing but just in case
      ps = sortregions(ps,'area','descend'); % make sure this is the last operation before selecting first since all other operations fry region order
      regs = regions(ps);
      ps = regs(1);

      [x,y] = centroid(ps);

      %Insert children as holes
      % Find all children of this parent
      children_idx = find(A(:, k) == 1);

      % % Add children (holes)
      for j = 1:length(children_idx)
         child_idx = children_idx(j);
         % child preprocessing
         child_boundary = B{child_idx};
         child_boundary = downsample(child_boundary, 2);


         child_ps = polyshape(child_boundary(:,2), child_boundary(:,1));

         child_ps = polybuffer(child_ps, 0.5, "JointType","square");
         child_ps = simplify(child_ps, "KeepCollinearPoints",false);

         child_ps_size = size(child_ps.Vertices);

         if (child_ps.NumRegions == 0 | child_ps_size < MIN_SIMPLIFIED_POINTS)
            continue
         end

         ps = xor(ps, child_ps);

      end

      simplified = ps.Vertices .* [1, -1];


      plot(x,y,'r*')
      plot(ps)
      boundary_num = boundary_num + 1;
      simple_bounds{1, boundary_num} = simplified;
      centroids{1, boundary_num} = [x,-y];

   end

end
boundary_nums(1) = boundary_num;

%TODO ensure all boundaires do not have elements that overlap

save('bad_apple.mat', 'simple_bounds', "num_frames", "centroids", "boundary_nums");



%% simplified with downsample

figure
imshow(label2rgb(L, @jet, [.5 .5 .5]))
hold on

num_frames = 2;

MIN_SIMPLIFIED_POINTS = 4;

simple_bounds = cell(length(B), num_frames);
centroids = cell(length(B), num_frames);
boundary_nums = zeros(1, num_frames);

boundary_num = 1;

for k = 1:length(B)
   boundary = B{k};
   plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)

   % By default bwboundaries provides coords in y, x
   ps = polyshape(boundary(:,2), boundary(:,1));
   %This xy is correct
   [x,y] = centroid(ps);

   plot(x,y,'r*')
   %Simplify boundary
   simplified = downsample(boundary, 1);
   simplified = simplified(:, [2, 1]) .* [1, -1]; % Convert to (x, y) and flip y (TODO this does flip but makes y negative)
   simplified_size = size(simplified);

   if (simplified_size(1) >= MIN_SIMPLIFIED_POINTS)
      simple_bounds{1, boundary_num} = simplified;
      centroids{1, boundary_num} = [x,-y];
      boundary_num = boundary_num + 1;
   end
end

save('bad_apple.mat', 'simple_bounds', "num_frames", "centroids", "boundary_nums");

%% First boundary debugging

figure;
hold on;
boundary = B{2};
plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 2)


% This seems to be the bad vertex (collinear points)
% find(ps.Vertices(:,1) == 243 & ps.Vertices(:,2) == 6 )


% By default polyshape simplifies
%ps = polyshape(boundary(:,2), boundary(:,1), "Simplify", false)
ps = polyshape(boundary(:,2), boundary(:,1))


ps = polybuffer(ps, 0.5, "JointType","square");
%ps = polybuffer(ps, -0.1);
%ps.Vertices(663,:) = []; % Removing problematic vertex for frame 0058 works

ps = simplify(ps, "KeepCollinearPoints",false);
%ps = rmslivers(ps,1); % THis techinically fixes the problem
ps = sortregions(ps,'area','descend');
plot(ps);
%This xy is correct
[x,y] = centroid(ps);

plot(x,y,'r*')

regs = regions(ps);   % split into 4 separate polyshapes

figure; hold on
cmap = lines(numel(regs));

for k = 1:numel(regs)
   plot(regs(k), ...
      'FaceColor', cmap(k,:), ...
      'EdgeColor', 'k', ...
      'FaceAlpha', 0.7);
   [cx, cy] = centroid(regs(k));
   text(cx, cy, num2str(k), ...
      'HorizontalAlignment','center', ...
      'FontSize',12, 'FontWeight','bold');
   k
   area(regs(k))
end

axis equal
hold off


%% Parent child resolving
figure
hold on

for k = 1:length(B)
   boundary = B{k};
   %This is parent OR child-less (Basically its not a child to anything)
   if (sum(A(k, :)) == 0) % Can also be predicated with (nnz(A(:,k)) > 0) for exclusively parents
      % Prepare vertices: parent followed by NaN-separated children
      all_vertices_x = boundary(:, 2); % x coords
      all_vertices_y = boundary(:, 1); % y coords
      % Create polyshape with holes
      ps = polyshape(all_vertices_x, all_vertices_y);
      plot(ps)
   end
end

%% All Children
figure
hold on
for k = 1:length(B)
   boundary = B{k};
   %This is parent OR child-less (Basically its not a child to anything)
   if (sum(A(k, :)) ~= 0) % Can also be predicated with (nnz(A(:,k)) > 0) for exclusively parents
      % Prepare vertices: parent followed by NaN-separated children
      all_vertices_x = boundary(:, 2); % x coords
      all_vertices_y = boundary(:, 1); % y coords
      % Create polyshape with holes
      ps = polyshape(all_vertices_x, all_vertices_y);
      plot(ps)
   end
end

%% Making holes from children
figure
hold on

for k = 1:length(B)
   boundary = B{k};
   %This is parent OR child-less (Basically its not a child to anything)
   if (sum(A(k, :)) == 0) % Can also be predicated with (nnz(A(:,k)) > 0) for exclusively parents

      % Prepare vertices: parent followed by NaN-separated children
      all_vertices_x = boundary(:, 2); % x coords
      all_vertices_y = boundary(:, 1); % y coords
      ps = polyshape(all_vertices_x, all_vertices_y);


      % Find all children of this parent
      children_idx = find(A(:, 1) == 1);

      % Add children (holes)
      for j = 1:length(children_idx)
         child_idx = children_idx(j);
         child_boundary = B{child_idx};
         child_ps = polyshape(child_boundary(:,2), child_boundary(:,1));
         ps = xor(ps, child_ps);

      end

      % Create polyshape with holes

      plot(ps)
   else
      % We are children
      continue
   end

end



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