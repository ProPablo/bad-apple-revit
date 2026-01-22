% Demonstrating Median Filter in Frequency Domain for Moiré Removal
clear; close all; clc;

fprintf('=== Moiré Pattern Removal Demo ===\n\n');

%% Step 1: Create image with moiré pattern
img = imread('cameraman.tif');
if size(img, 3) == 3
    img = rgb2gray(img);
end
img = im2double(img);

% Create moiré pattern (sinusoidal interference)
[rows, cols] = size(img);
[X, Y] = meshgrid(1:cols, 1:rows);

% Two sinusoidal patterns that create moiré
freq1_x = 0.15; freq1_y = 0.1;
freq2_x = 0.12; freq2_y = 0.13;

moire1 = 0.3 * sin(2*pi*freq1_x*X + 2*pi*freq1_y*Y);
moire2 = 0.3 * sin(2*pi*freq2_x*X + 2*pi*freq2_y*Y);
moire_pattern = moire1 + moire2;

% Add moiré to image
noisy_img = img + moire_pattern;
noisy_img = max(0, min(1, noisy_img)); % Clip to valid range

fprintf('Moiré pattern added to image\n');

%% Step 2: FFT Analysis
fft_original = fftshift(fft2(img));
fft_noisy = fftshift(fft2(noisy_img));

% Display spectrum
mag_original = log(1 + abs(fft_original));
mag_noisy = log(1 + abs(fft_noisy));

figure('Position', [50, 50, 1400, 1000]);

subplot(3, 4, 1); imshow(img); title('Original Image');
subplot(3, 4, 2); imshow(noisy_img); title('Image with Moiré Pattern');
subplot(3, 4, 5); imshow(mag_original, []); title('FFT: Original');
subplot(3, 4, 6); imshow(mag_noisy, []); title('FFT: Noisy (See Impulses!)');

fprintf('\nMoiré pattern creates IMPULSE PAIRS in frequency domain\n');

%% Step 3: Locate moiré impulses
% Find peaks in difference spectrum
diff_spectrum = abs(fft_noisy) - abs(fft_original);
threshold = 0.3 * max(diff_spectrum(:));

% Find impulse locations
[peak_rows, peak_cols] = find(diff_spectrum > threshold);

% Show impulse locations
subplot(3, 4, 7);
imshow(mag_noisy, []); hold on;
plot(peak_cols, peak_rows, 'r.', 'MarkerSize', 15);
title(sprintf('Identified %d Impulse Locations', length(peak_rows)));

fprintf('Found %d impulse locations from moiré pattern\n', length(peak_rows));

%% Step 4: Method 1 - Traditional Notch Filter
fprintf('\n--- Method 1: Notch Filter (Traditional) ---\n');

fft_notch = fft_noisy;
notch_radius = 3; % Radius of notch

% Zero out impulse locations
for i = 1:length(peak_rows)
    r = peak_rows(i);
    c = peak_cols(i);
    
    % Create circular notch
    [yy, xx] = meshgrid(1:cols, 1:rows);
    dist = sqrt((xx - r).^2 + (yy - c).^2);
    notch_mask = dist <= notch_radius;
    
    fft_notch(notch_mask) = 0; % COMPLETE REMOVAL
end

% Reconstruct image
denoised_notch = real(ifft2(ifftshift(fft_notch)));
denoised_notch = max(0, min(1, denoised_notch));

psnr_notch = psnr(denoised_notch, img);
fprintf('PSNR (Notch Filter): %.2f dB\n', psnr_notch);

subplot(3, 4, 3); imshow(denoised_notch);
title(sprintf('Notch Filter (PSNR: %.2f dB)', psnr_notch));

subplot(3, 4, 8); imshow(log(1 + abs(fft_notch)), []);
title('FFT after Notch Filter (Zeros!)');

%% Step 5: Method 2 - Median Filter in Frequency Domain (Paper's Method)
fprintf('\n--- Method 2: Median Filter in Frequency Domain ---\n');

fft_median = fft_noisy;
window_size = 5; % Median filter window

% Apply median filter ONLY at impulse locations
for i = 1:length(peak_rows)
    r = peak_rows(i);
    c = peak_cols(i);
    
    % Extract neighborhood (avoid boundaries)
    r_start = max(1, r - floor(window_size/2));
    r_end = min(rows, r + floor(window_size/2));
    c_start = max(1, c - floor(window_size/2));
    c_end = min(cols, c + floor(window_size/2));
    
    % Get window around impulse
    window = fft_median(r_start:r_end, c_start:c_end);
    
    % Apply median to MAGNITUDE only (preserve phase)
    mag_window = abs(window);
    phase_center = angle(fft_median(r, c));
    
    % Replace with median magnitude
    median_mag = median(mag_window(:));
    fft_median(r, c) = median_mag * exp(1i * phase_center);
end

% Reconstruct image
denoised_median = real(ifft2(ifftshift(fft_median)));
denoised_median = max(0, min(1, denoised_median));

psnr_median = psnr(denoised_median, img);
fprintf('PSNR (Median in Freq Domain): %.2f dB\n', psnr_median);

subplot(3, 4, 4); imshow(denoised_median);
title(sprintf('Median Filter (PSNR: %.2f dB)', psnr_median));

subplot(3, 4, 9); imshow(log(1 + abs(fft_median)), []);
title('FFT after Median Filter (Estimated!)');

%% Step 6: Comparison - Zoom on impulse location
if length(peak_rows) > 0
    % Pick first impulse location
    r = peak_rows(1);
    c = peak_cols(1);
    
    zoom_range = 20;
    r_range = max(1, r-zoom_range):min(rows, r+zoom_range);
    c_range = max(1, c-zoom_range):min(cols, c+zoom_range);
    
    subplot(3, 4, 10);
    imagesc(abs(fft_noisy(r_range, c_range)));
    colorbar; title('Noisy (Zoomed on Impulse)');
    
    subplot(3, 4, 11);
    imagesc(abs(fft_notch(r_range, c_range)));
    colorbar; title('After Notch (Zeroed)');
    
    subplot(3, 4, 12);
    imagesc(abs(fft_median(r_range, c_range)));
    colorbar; title('After Median (Estimated)');
end

%% Step 7: Key insights
fprintf('\n=== KEY INSIGHTS ===\n');
fprintf('1. Moiré patterns create ISOLATED impulses in frequency domain\n');
fprintf('2. Notch filter: Completely removes those frequencies (loses signal too)\n');
fprintf('3. Median filter: ESTIMATES spectrum from neighbors (preserves more signal)\n');
fprintf('4. This ONLY works because:\n');
fprintf('   - Noise is localized to specific frequencies\n');
fprintf('   - Natural images have smooth, continuous spectra\n');
fprintf('   - Neighboring frequency values can estimate the "true" value\n');
fprintf('\n5. This is NOT the same as spatial domain median filtering!\n');
fprintf('   - Applied in frequency domain\n');
fprintf('   - Only at specific impulse locations\n');
fprintf('   - Uses frequency continuity property\n');

%% Step 8: Show why this doesn't work for general median filtering
fprintf('\n=== Why You Cannot Do General Median Filtering in Frequency Domain ===\n');

% Try to apply median filter everywhere in frequency domain
fprintf('Attempting median filter on entire spectrum...\n');

fft_full_median = fft_noisy;
med_window = 3;
pad = floor(med_window/2);

for i = 1+pad:rows-pad
    for j = 1+pad:cols-pad
        window = abs(fft_noisy(i-pad:i+pad, j-pad:j+pad));
        fft_full_median(i,j) = median(window(:)) * exp(1i*angle(fft_noisy(i,j)));
    end
end

full_median_result = real(ifft2(ifftshift(fft_full_median)));
full_median_result = max(0, min(1, full_median_result));

figure('Name', 'Why Full Frequency Domain Median Fails');
subplot(1,3,1); imshow(img); title('Original');
subplot(1,3,2); imshow(full_median_result); title('Median Filter on ENTIRE Spectrum');
subplot(1,3,3); imshow(abs(img - full_median_result), []); 
title('Error (This approach distorts the image!)');

fprintf('\nApplying median to entire spectrum destroys the image!\n');
fprintf('The paper''s method works ONLY because it targets specific impulses.\n');