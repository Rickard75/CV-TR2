%% Open and Plot Intensity Histogram over entire image

folder = "test_images/apples_images/";
filenumber = input("Insert image number (without path): "); % use ""
filename = "Image_" + filenumber + ".tiff";
fullname = folder + filename;
img_raw = imread(fullname);
[height, width] = size(img_raw);
fprintf("Height: %d px\nWidth %d px\n", height, width);
figure('Name', 'Istogramma Intensità');
histogram(img_raw(:), 512);
title('Intensità SWIR');
xlabel('Intensità [a.u.]');
ylabel('Pixel count');
pause(3);
close;

disp("Basic Statistics of the Image");
min_val = min(img_raw(:));
max_val = max(img_raw(:));
mean_val = mean(img_raw(:));
std_val = std(double(img_raw(:)));
fprintf("Min: %d, Max: %d, Mean: %.2f, Std: %.2f\n", ...
    min_val, max_val, mean_val, std_val);

%% Goals of the Analysis

% Finding the ROI of the image:
% 1. find ROIx: 
%       ✅ - extract (left_px, right_px) for 1 single horiz. stripe 
%       ✅ - average over all horizontal stripes width boundaries ...
%         for ca.100px at I>=2000
% 2. find ROIy: height boundaries for same parameters
%       - extract fpr 1
%       - average over all vertical stripes
% 3. found ROI=(ROIx,ROIy) for 1 image
% 4. repeat for N images

%% 1.1X Finding ROIx for one single LINE (1x1024)

img_raw = imread(fullname);
row_idx = round(size(img_raw,1) / 2); % for instance, the central line
row_line = img_raw(row_idx, :);  

%{ unuseful plot with just intensity and threshold
figure;
plot(row_line);
yline(2000, 'r--', 'LineWidth',2);
xlabel('Column index'); ylabel('Intensity [a.u.]');
title(sprintf('Intensity of line %d (1x%d)', row_idx, length(line)));
%}

thr_appleX = 1000; % a.u.
min_lengthX = 100; % px
mask_overthrX = row_line >= thr_appleX;
disp(mask_overthrX);

inside = false;
left_px = NaN;
right_px = NaN;
length_counter = 0;

% LOOP over one row-line
for i = 1:length(row_line)
    if mask_overthrX(i)
        if ~inside
            % Entering ROIx if intensity>threshold
            inside = true;
            length_counter = 1;
            temp_left = i;
        else
            length_counter = length_counter + 1;
        end
    else
        if inside
            % Exit ROIx
            if length_counter >= min_lengthX
                left_px = temp_left;
                right_px = i - 1;  % previous px is still valid
                break; % ignoring other regions, just the first
            end
            % Reset if region too short
            inside = false;
            length_counter = 0;
        end
    end
end

if ~isnan(left_px)
    fprintf("✅ ROIx found:\nLeft px: %d\nRight px: %d\n", left_px, right_px);
else
    fprintf("❌ No region found over threshold %d for at least %d consectuive pixels.\n", thr_appleX, min_lengthX);
end

% Plotting
figure;
plot(row_line, 'b'); hold on;
yline(thr_appleX, 'r--');
xlabel('Column Index [px]'); 
ylabel('Intensity Value [a.u.]');

% Highlight detected region
if ~isnan(left_px)
    x = left_px:right_px;
    plot(x, row_line(x), 'g', 'LineWidth', 2);
    legend('Signal', 'Threshold', 'ROIx');
    title(sprintf('Image: %s\n1D x-Profile with Threshold %d\n(start = %d, end = %d)', filename, thr_appleX, left_px, right_px), 'Interpreter','none');
else
    title('1D Profile - No Region Detected');
end

%% 1.1Y Finding ROIy for one single LINE (256x1)

col_idx = round(size(img_raw, 2) / 2); % central column
col_line = img_raw(:, col_idx);         % vertical profile (Y axis)

% Adjust threshold and min_length
thr_appleY = 800; % a.u.
min_lengthY = 50; % px
mask_overthr_y = col_line >= thr_appleY;
disp(mask_overthr_y);

inside = false;
top_px = NaN;
bottom_px = NaN;
length_counter = 0;

% LOOP over one column-line
for j = 1:length(col_line)
    if mask_overthr_y(j)
        if ~inside
            % Entering ROIy
            inside = true;
            length_counter = 1;
            temp_top = j;
        else
            length_counter = length_counter + 1;
        end
    else
        if inside
            if length_counter >= min_lengthY
                top_px = temp_top;
                bottom_px = j - 1;
                break;
            end
            inside = false;
            length_counter = 0;
        end
    end
end

if ~isnan(top_px)
    fprintf("✅ ROIy found:\nTop px: %d\nBottom px: %d\n", top_px, bottom_px);
else
    fprintf("❌ No vertical region found over threshold %d for at least %d consectuive pixels.\n", thr_appleY, min_lengthY);
end

% Plotting
figure;
plot(col_line, 'b'); hold on;
yline(thr_appleY, 'r--');
xlabel('Row Index [px]');
ylabel('Intensity Value [a.u.]');

% Highlight detected vertical region
if ~isnan(top_px)
    y_segment = top_px:bottom_px;
    plot(y_segment, col_line(y_segment), 'g', 'LineWidth', 2);
    legend('Signal', 'Threshold', 'ROIy');
    title(sprintf('Image: %s\n1D y-Profile with Threshold %d\n(start = %d, end = %d)', filename, thr_appleY, bottom_px, top_px), 'Interpreter','none');
else
    title('1D Vertical Profile - No Region Detected');
end

%% TEST for BOUNDING-BOX from two SINGLE LINES (referred to central)
fprintf("ROIx: (%d,%d)\nROIy: (%d,%d)\n", left_px, right_px, bottom_px, top_px)
roi_central_crop = img_raw(top_px:bottom_px, left_px:right_px);

[height, width] = size(img_raw);
fprintf("Image size: %d rows (Y), %d columns (X)\n", height, width);

if left_px < 1 || right_px > width || bottom_px < 1 || top_px > height
    error("❌ ROI boundaries are outside the image limits.");
end

% Print cropped image
figure;
imshow(roi_central_crop, []); % adjust contrast automatically
title(sprintf('ROI View: X = [%d:%d], Y = [%d:%d]', left_px, right_px, top_px, bottom_px));

% Print full image with bounding-box
figure;
imshow(img_raw,[]);
hold on;
boundingbox_width = right_px - left_px;
boundingbox_height = bottom_px - top_px;
rectangle('Position',[left_px, top_px, boundingbox_width, boundingbox_height], 'EdgeColor', 'r', 'LineWidth', 2); % eats the vertex in the upper-left
title(sprintf("Full image with bounded box (central line finder)"))
%% 1.2X Finding ROIx for one single IMAGE (256x1024)

img_raw = imread(fullname);
num_lines = 256;    % number of rows to scan

roi_bounds = NaN(num_lines, 2);  % initialize output matrix
disp('/////////////////////////////////////////////////')
disp('/  Finding ROIx for one single IMAGE (256x1024) /')
disp('/////////////////////////////////////////////////')
disp('Starting loop over lines...')
for row_idx = 1:num_lines
    %fprintf("Analyzing line %d\n", row_idx)
    line = img_raw(row_idx, :);  % extract current line
    mask_overthr = row_line >= thr_appleX;

    inside = false;
    left_px = NaN;
    right_px = NaN;
    length_counter = 0;

    for i = 1:length(row_line)
        if mask_overthr(i)
            if ~inside
                inside = true;
                length_counter = 1;
                temp_left = i;
            else
                length_counter = length_counter + 1;
            end
        else
            if inside
                if length_counter >= min_lengthX
                    left_px = temp_left;
                    right_px = i - 1;
                    break;  % only first region
                end
                inside = false;
                length_counter = 0;
            end
        end
    end

    % Save results in the matrix
    roi_bounds(row_idx, :) = [left_px, right_px];
end
disp('Finished loop over lines.')

% Filter out rows where either left or right is NaN
%disp('------------------VALID ROIx BOUNDS-------------------');
valid_roi_bounds = roi_bounds(~any(isnan(roi_bounds), 2), :); 
%disp(valid_roi_bounds);

% Averaging over the valid stripes that respect trigger conditions
% (I>2000,t>100)
avg_roi_x1 = 0;
avg_roi_x2 = 0;
sum_roi_x1 = 0;
sum_roi_x2 = 0;
for i=1:length(valid_roi_bounds)
    sum_roi_x1 = sum_roi_x1 + valid_roi_bounds(i,1);
    sum_roi_x2 = sum_roi_x2 + valid_roi_bounds(i,2);
end
avg_roi_x1 = round(sum_roi_x1/length(valid_roi_bounds));
avg_roi_x2 = round(sum_roi_x2/length(valid_roi_bounds));
disp('------------------MEAN ROIx BOUNDS-------------------');
fprintf('Mean ROIx for image %s is ROIx = (%d,%d)\n\n', filename, avg_roi_x1, avg_roi_x2);

%% 1.2Y Finding ROIy for one single IMAGE (256x1024)

num_cols = size(img_raw, 2);  % number of columns to scan (1024)
roi_bounds_y = NaN(num_cols, 2);  % initialize output matrix

disp('/////////////////////////////////////////////////')
disp('/  Finding ROIy for one single IMAGE (256x1024) /')
disp('/////////////////////////////////////////////////')
disp('Starting loop over columns...')
for col_idx = 1:num_cols
    column = img_raw(:, col_idx);  % extract current column
    mask_overthr_y = column >= thr_appleY;

    inside = false;
    top_px = NaN;
    bottom_px = NaN;
    length_counter = 0;

    for j = 1:length(column)
        if mask_overthr_y(j)
            if ~inside
                inside = true;
                length_counter = 1;
                temp_top = j;
            else
                length_counter = length_counter + 1;
            end
        else
            if inside
                if length_counter >= min_lengthY
                    top_px = temp_top;
                    bottom_px = j - 1;
                    break;  % only first valid region
                end
                inside = false;
                length_counter = 0;
            end
        end
    end

    % Save results in the matrix
    roi_bounds_y(col_idx, :) = [top_px, bottom_px];
end
disp('Finished loop over columns.')

% Filter out columns where either top or bottom is NaN
valid_roi_bounds_y = roi_bounds_y(~any(isnan(roi_bounds_y), 2), :); 

% Averaging over the valid columns that respect trigger conditions
avg_roi_y1 = 0;
avg_roi_y2 = 0;
sum_roi_y1 = 0;
sum_roi_y2 = 0;
for i = 1:length(valid_roi_bounds_y)
    sum_roi_y1 = sum_roi_y1 + valid_roi_bounds_y(i, 1);
    sum_roi_y2 = sum_roi_y2 + valid_roi_bounds_y(i, 2);
end
avg_roi_y1 = round(sum_roi_y1 / length(valid_roi_bounds_y));
avg_roi_y2 = round(sum_roi_y2 / length(valid_roi_bounds_y));

disp('------------------MEAN ROIy BOUNDS-------------------');
fprintf('Mean ROIy for image %s is ROIy = (%d,%d)\n\n', filename, avg_roi_y1, avg_roi_y2);

%% TEST for BOUNDING-BOX from two ALL LINES
fprintf("ROIx: (%d,%d)\nROIy: (%d,%d)\n", avg_roi_x1, avg_roi_x2, avg_roi_y1, avg_roi_y2);
roi_central_crop = img_raw(avg_roi_y2:avg_roi_y1, avg_roi_x1:avg_roi_x2);

[height, width] = size(img_raw);
fprintf("Image size: %d rows (Y), %d columns (X)\n", height, width);

if avg_roi_x1 < 1 || avg_roi_x2 > width || avg_roi_y1 < 1 || avg_roi_y2 > height
    error("❌ ROI boundaries are outside the image limits.");
end

% Print cropped image
figure;
imshow(roi_central_crop, []); % adjust contrast automatically
title(sprintf('ROI View: X = [%d:%d], Y = [%d:%d]', avg_roi_x1, avg_roi_x2, avg_roi_y1, avg_roi_y2));

% Print full image with bounding-box
figure;
imshow(img_raw,[]);
hold on;
boundingbox_width = avg_roi_x2 - avg_roi_x1;
boundingbox_height = avg_roi_y2 - avg_roi_y1;
rectangle('Position',[avg_roi_x1, avg_roi_y2, boundingbox_width, boundingbox_height], 'EdgeColor', 'r', 'LineWidth', 2); % eats the vertex in the upper-left
title(sprintf("Full image with bounded box (full finder)"))

%% Finding ROIx for multiple IMAGES (256x1024xNUM_FILES)

fprintf('\nStart analyzing files...\n')
% Folder path
folder_path = "test_images/apples_images";
image_files = dir(fullfile(folder_path, "*.tiff"));

% DEBUG: list found files
if isempty(image_files)
    error("❌ No .tiff files found in folder: %s\n", folder_path);
else
    fprintf("✅ Found %d .tiff files in folder: %s\n", length(image_files), folder_path);
    disp({image_files.name}');
end

% Set number of lines to analyze per image
num_lines = 256;  % can be changed freely
thr_apple = 2000;
min_length = 100;

% Initialize accumulators for all images
total_avg_roi_x = 0;
total_avg_roi_y = 0;
num_files = length(image_files);  % or set manually if you want fewer

for idx = 1:num_files
    filename = fullfile(image_files(idx).folder, image_files(idx).name);
    img_raw = imread(filename);

    roi_bounds = NaN(num_lines, 2);

    % Loop through each line
    for row_idx = 1:num_lines
        line = img_raw(row_idx, :);
        mask_overthr = line >= thr_apple;

        inside = false;
        left_px = NaN;
        right_px = NaN;
        length_counter = 0;

        for i = 1:length(line)
            if mask_overthr(i)
                if ~inside
                    inside = true;
                    length_counter = 1;
                    temp_left = i;
                else
                    length_counter = length_counter + 1;
                end
            else
                if inside
                    if length_counter >= min_length
                        left_px = temp_left;
                        right_px = i - 1;
                        break;
                    end
                    inside = false;
                    length_counter = 0;
                end
            end
        end

        roi_bounds(row_idx, :) = [left_px, right_px];
    end

    % Filter valid ROI bounds
    valid_roi_bounds = roi_bounds(~any(isnan(roi_bounds), 2), :);

    % Compute mean ROI bounds for this image
    avg_roi_x = round(mean(valid_roi_bounds(:,1)));
    avg_roi_y = round(mean(valid_roi_bounds(:,2)));

    % Accumulate for overall stats
    total_avg_roi_x = total_avg_roi_x + avg_roi_x;
    total_avg_roi_y = total_avg_roi_y + avg_roi_y;

    % Print result for this image
    fprintf('Mean ROIx for image %s is ROIx = (%d,%d)\n', ...
        image_files(idx).name, avg_roi_x, avg_roi_y);
end

% Final mean over all images
avg_roi_x_all = round(total_avg_roi_x / num_files);
avg_roi_y_all = round(total_avg_roi_y / num_files);

fprintf('\nGLOBAL MEAN ROIx across %d images: (%d, %d)\n', ...
    num_files, avg_roi_x_all, avg_roi_y_all);

fprintf('Analysis completed.\n---------------------------------------------\n')

%% Visualize CENTER LINES plots for MULTIPLE IMAGES
function show_center_lines(selection)
    % === PARAMETERS ===
    folder_path = "test_images/apples_images";
    thr_apple = 2000;
    min_length = 100;

    % Load image list
    image_files = dir(fullfile(folder_path, "*.tiff"));
    if isempty(image_files)
        error("❌ No .tiff files found in folder: %s\n", folder_path);
    end

    if ischar(selection)
        selection = string(selection);
    end

    for idx = 1:length(image_files)
        filename = image_files(idx).name;

        if any(strcmp(selection,"all")) || any(strcmp(selection,filename))
            full_path = fullfile(image_files(idx).folder, filename);
            img = imread(full_path);

            % Central row
            central_row = round(size(img, 1) / 2);
            line = img(central_row, :);
            mask = line >= thr_apple;

            % ROI detection
            inside = false;
            left_px = NaN;
            right_px = NaN;
            length_counter = 0;

            for i = 1:length(line)
                if mask(i)
                    if ~inside
                        inside = true;
                        length_counter = 1;
                        temp_left = i;
                    else
                        length_counter = length_counter + 1;
                    end
                else
                    if inside
                        if length_counter >= min_length
                            left_px = temp_left;
                            right_px = i - 1;
                            break;
                        end
                        inside = false;
                        length_counter = 0;
                    end
                end
            end

            % === PLOT ===
            figure;
            plot(line, 'b'); hold on;
            yline(thr_apple, 'r--', 'Threshold');

            if ~isnan(left_px)
                x = left_px:right_px;
                plot(x, line(x), 'g', 'LineWidth', 2);
                legend('Center line', 'Threshold', ...
                       sprintf('ROIx [%d:%d]', left_px, right_px), ...
                       'Location', 'best');
                title(sprintf('%s - Line %d\nROI = [%d, %d]', ...
                      filename, central_row, left_px, right_px), ...
                      'Interpreter', 'none');
            else
                legend('Center line', 'Threshold', ...
                       'Location', 'best');
                title(sprintf('%s - Line %d\nNo ROI found', ...
                      filename, central_row), ...
                      'Interpreter', 'none');
            end

            xlabel('Column Index [px]');
            ylabel('Intensity [a.u.]');
        end
    end
end

%{
    //////////////////////////////////////////////////
    /                   MAIN                         /
    //////////////////////////////////////////////////
%}

%show_center_lines("Image_69.tiff");  % solo una immagine
show_center_lines(["Image_77.tiff", "Image_69.tiff"]);  % più immagini
%show_center_lines("all");  % tutte le immagini nella cartella

