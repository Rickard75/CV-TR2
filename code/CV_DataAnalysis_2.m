%/////////////////////////////////////////////////////
%               F U N C T I O N S
%/////////////////////////////////////////////////////

function [start_px, end_px] = roi_bounds_1D(line, threshold, min_length)
    mask = line >= threshold;
    inside = false;
    start_px = NaN;
    end_px = NaN;
    length_counter = 0;

    for i = 1:length(line)
        if mask(i)
            if ~inside
                inside = true;
                length_counter = 1;
                temp_start = i;
            else
                length_counter = length_counter + 1;
            end
        else
            if inside
                if length_counter >= min_length
                    start_px = temp_start;
                    end_px = i - 1;
                    return;
                end
                inside = false;
                length_counter = 0;
            end
        end
    end
end

function [mean_start, mean_end] = roi_bounds_image(img, threshold, min_length, direction, x_range)
    
    % Choose direction to scan
     if direction == 'x'
        num_lines = size(img, 1);  % righe
        dim = size(img, 2);        % colonne
    elseif direction == 'y'
        num_lines = size(img, 2);  % colonne
        dim = size(img, 1);        % righe
    else
        error("Direction must be 'x' or 'y'");
    end

    roi_bounds = NaN(num_lines, 2); % to store [start_px, end_px]
    % Loop over lines
    for idx = 1:num_lines
        if direction == 'x'
            line = img(idx, :); % get one row-line
        else
            line = img(:, idx); % get one col-line
        end
        [start_px, end_px] = roi_bounds_1D(line, threshold, min_length);
        roi_bounds(idx, :) = [start_px, end_px]; % store boundaries for each single line
    end

    valid_bounds = roi_bounds(~any(isnan(roi_bounds), 2), :); % cancel values under threshold
    mean_start = round(mean(valid_bounds(:, 1)));
    mean_end = round(mean(valid_bounds(:, 2)));
end

function plot_single_roi(img, roi_start, roi_end, direction, title_suffix)
    if nargin < 5
        title_suffix = '';
    end

    % Profilo centrale (riga o colonna)
    if direction == 'x'
        idx = round(size(img, 1) / 2);      % riga centrale
        profile = img(idx, :);              % profilo orizzontale
        line_indices = 1:size(img, 2);      % colonne

        % Plot profilo orizzontale
        figure;
        plot(line_indices, profile, 'b'); hold on;
        yline(min(profile(roi_start:roi_end)), 'r--', 'Threshold');
        plot(roi_start:roi_end, profile(roi_start:roi_end), 'g', 'LineWidth', 2);
        legend('Intensità', 'Soglia', 'ROI');
        xlabel('Colonne [px]');
        ylabel('Intensità [a.u.]');
        title(sprintf('Profilo orizzontale %s – ROI [%d:%d]', title_suffix, roi_start, roi_end), 'Interpreter','none');

        % Immagine con bounding box orizzontale
        figure;
        imshow(img, []); hold on;
        height = size(img, 1);
        rectangle('Position', [roi_start, 1, roi_end - roi_start, height], ...
                  'EdgeColor', 'r', 'LineWidth', 2);
        title(sprintf('Box orizzontale – ROIx [%d:%d] %s', roi_start, roi_end, title_suffix), 'Interpreter','none');

    elseif direction == 'y'
        idx = round(size(img, 2) / 2);      % colonna centrale
        profile = img(:, idx);              % profilo verticale
        line_indices = 1:size(img, 1);      % righe

        % Plot profilo verticale
        figure;
        plot(line_indices, profile, 'b'); hold on;
        yline(min(profile(roi_start:roi_end)), 'r--', 'Threshold');
        plot(roi_start:roi_end, profile(roi_start:roi_end), 'g', 'LineWidth', 2);
        legend('Intensità', 'Soglia', 'ROI');
        xlabel('Righe [px]');
        ylabel('Intensità [a.u.]');
        title(sprintf('Profilo verticale %s – ROI [%d:%d]', title_suffix, roi_start, roi_end), 'Interpreter','none');

        % Immagine con bounding box verticale
        figure;
        imshow(img, []); hold on;
        width = size(img, 2);
        rectangle('Position', [1, roi_start, width, roi_end - roi_start], ...
                  'EdgeColor', 'r', 'LineWidth', 2);
        title(sprintf('Box verticale – ROIy [%d:%d] %s', roi_start, roi_end, title_suffix), 'Interpreter','none');
    else
        error("Direzione non valida. Usa 'x' o 'y'.");
    end
end

function plot_crop_box(img, roi_x1, roi_x2, roi_y1, roi_y2, title_suffix)
    if nargin < 6
        title_suffix = '';
    end

    % === CROP e ZOOM ===
    roi_crop = img(roi_y1:roi_y2, roi_x1:roi_x2);
    figure;
    imshow(roi_crop, []);
    title(sprintf("ROI Croppata [%d:%d, %d:%d] %s", ...
        roi_y1, roi_y2, roi_x1, roi_x2, title_suffix), ...
        'Interpreter','none');

    % === BOX SULL'IMMAGINE ORIGINALE ===
    figure;
    imshow(img, []); hold on;
    box_width = roi_x2 - roi_x1;
    box_height = roi_y2 - roi_y1;
    rectangle('Position', [roi_x1, roi_y1, box_width, box_height], ...
              'EdgeColor', 'r', 'LineWidth', 2);
    title(sprintf("Bounding Box 2D – ROIx: [%d,%d], ROIy: [%d,%d] %s", ...
        roi_x1, roi_x2, roi_y1, roi_y2, title_suffix), ...
        'Interpreter','none');
end

function plot_intensity_profiles_grid(img, step)
    if nargin < 2
        step = 10;
    end

    [height, width] = size(img);

    % === PROFILI ORIZZONTALI (righe) ===
    figure('Name', 'Profili Orizzontali (righe → X)');
    hold on;
    for row = 1:step:height
        plot(1:width, img(row, :));
    end
    xlabel('Colonne [px]');
    ylabel('Intensità [a.u.]');
    title(sprintf('Profili orizzontali (una riga ogni %d)', step));
    grid on;
    hold off;

    % === PROFILI VERTICALI (colonne) ===
    figure('Name', 'Profili Verticali (colonne → Y)');
    hold on;
    for col = 1:step:width
        plot(1:height, img(:, col));
    end
    xlabel('Righe [px]');
    ylabel('Intensità [a.u.]');
    title(sprintf('Profili verticali (una colonna ogni %d)', step));
    grid on;
    hold off;
end

function close_all_figures()
    figs = findall(0, 'Type', 'figure');
    
    if isempty(figs)
        disp("ℹ️ Nessuna finestra aperta da chiudere.");
        return;
    end

    prompt = "Vuoi chiudere tutte le finestre grafiche? [s/n]: ";
    user_input = lower(strtrim(input(prompt, 's')));

    switch user_input
        case {'s', 'si', 'sì', 'y', 'yes'}
            close(figs);
            disp("✅ Finestre grafiche chiuse.");
        otherwise
            disp("❎ Operazione annullata. Nessuna finestra chiusa.");
    end
end


%/////////////////////////////////////////////////////
%               P A R A M E T E R S                  /
%/////////////////////////////////////////////////////

thr_appleX = 800;
thr_appleY = 600;
min_lengthX = 100;
min_lengthY = 50;

%/////////////////////////////////////////////////////
%                   M A I N                          /
%/////////////////////////////////////////////////////

% Loading image
filename = fullfile("test_images/apples_images", "Image_87.tiff");
img_raw = imread(filename);
imshow(img_raw,[]);

% Define restricted x-range to belt zone
%{
title("Draw a horizontal line over the belt zone...");
h = drawline('Color','r','LineWidth',2);
points = round(h.Position);
left_x = min(points(:,1));
right_x = max(points(:,1));
fprintf("You selected zone: [%d,%d]", left_x, right_x);
belt_roi_x = [left_x, right_x];
%}

% ROIx e ROIy
[roi_x1, roi_x2] = roi_bounds_image(img_raw, thr_appleX, min_lengthX, 'x'); %364,742
[roi_y1, roi_y2] = roi_bounds_image(img_raw, thr_appleY, min_lengthY, 'y');

%plot_single_roi(img_raw, roi_x1, roi_x2, 'x', 'Image_69.tiff');
%plot_single_roi(img_raw, roi_y1, roi_y2, 'y', 'Image_69.tiff');
plot_crop_box(img_raw, roi_x1, roi_x2, roi_y1, roi_y2, 'Image_69.tiff');
%plot_intensity_profiles_grid(img_raw, 50);  % ogni 10 righe/colonne
close_all_figures();
