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

function plot_box_only(img, roi_x1, roi_x2, roi_y1, roi_y2, title_suffix)
    if nargin < 6
        title_suffix = '';
    end

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
        disp("ℹ️ No open windows to open.");
        return;
    end

    prompt = "Do you want to close all graphic windows? [y/n]: ";
    user_input = lower(strtrim(input(prompt, 's')));

    switch user_input
        case {'s', 'si', 'sì', 'y', 'yes'}
            close(figs);
            disp("✅ Graphic windows closed.");
        otherwise
            disp("❎ Operation failed. No windows closed.");
    end
end

function [mean_start, mean_end] = roi_bounds_image_2(img, threshold, min_length, direction, pixel_range)
    % Calcola la ROI media sulle linee/colonne dell'immagine,
    % considerando solo un sotto-intervallo dei pixel nella linea
    %
    % pixel_range = [start_px end_px] → es. [100 200] limita la linea
    disp(nargin)
    if nargin < 5
        error("Devi specificare il range dei pixel da considerare nella linea.");
    end

    if direction == 'x'
        num_lines = size(img, 1);  % analizzi tutte le righe
    elseif direction == 'y'
        num_lines = size(img, 2);  % analizzi tutte le colonne
    else
        error("Direction must be 'x' or 'y'");
    end

    roi_bounds = NaN(num_lines, 2);  % [start, end] per ciascuna linea

    for idx = 1:num_lines
        if direction == 'x'
            line = img(idx, :);
        else
            line = img(:, idx);
        end

        % Estrai solo il range di pixel desiderato nella linea
        if pixel_range(1) >= 1 && pixel_range(2) <= length(line)
            subline = line(pixel_range(1):pixel_range(2));
        else
            error("❌ pixel_range fuori dai limiti della linea.");
        end

        % Applica rilevamento ROI su quel sottointervallo
        [start_sub, end_sub] = roi_bounds_1D(subline, threshold, min_length);

        % Riadatta alle coordinate assolute rispetto all'immagine
        if ~isnan(start_sub)
            start_abs = start_sub + pixel_range(1) - 1;
            end_abs   = end_sub + pixel_range(1) - 1;
        else
            start_abs = NaN;
            end_abs = NaN;
        end

        roi_bounds(idx, :) = [start_abs, end_abs];
    end

    % Media sulle linee valide
    valid_bounds = roi_bounds(~any(isnan(roi_bounds), 2), :);

    mean_start = round(mean(valid_bounds(:, 1)));
    mean_end = round(mean(valid_bounds(:, 2)));
end

function img_multiplots_roi(folder_path, results)

    % Visualizza massimo 9 immagini in griglia 3x3 con bounding box (se fornita)
    % INPUT:
    %   folder_path - percorso immagini .tiff
    %   results     - tabella opzionale con bounding box per ogni immagine

    image_files = dir(fullfile(folder_path, '*.tiff'));
    num_images = min(9, length(image_files));

    if num_images == 0
        error('Nessuna immagine trovata nella cartella %s', folder_path);
    end

    figure('Name', 'Grid 3x3', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

    for i = 1:num_images
        fname = image_files(i).name;
        fullpath = fullfile(folder_path, fname);
        img = imread(fullpath);

        subplot(3,3,i);
        imshow(img, []); hold on;
        title(fname, 'Interpreter','none', 'FontSize', 9);

        % Se fornita, disegna bounding box
        if nargin > 1 && ~isempty(results)
            idx = find(strcmp(results.Filename,fname));
            if ~isempty(idx)
                x1 = results.ROI_X1(idx);
                x2 = results.ROI_X2(idx);
                y1 = results.ROI_Y1(idx);
                y2 = results.ROI_Y2(idx);
                if all(~isnan([x1 x2 y1 y2]))
                    rectangle('Position', [x1, y1, x2 - x1, y2 - y1], ...
                              'EdgeColor', 'r', 'LineWidth', 1.5);
                end
            end
        end
    end
end

function img_multiplots(img_start, img_end, num_img, folder)
    % Visualizza più immagini in una griglia con contrasto adattivo
    % da "Image_XX.tiff" dove XX va da img_start a img_end (incluso).
    % Mostra solo le prime num_img immagini del range.

    count = 0;
    img_ids = img_start:img_end;
    img_ids = img_ids(1:min(num_img, length(img_ids)));

    n = length(img_ids);
    ncols = ceil(sqrt(n));
    nrows = ceil(n / ncols);

    figure('Name', sprintf('Immagini da %d a %d', img_start, img_end), ...
           'Units','normalized', 'Position',[0.1 0.1 0.8 0.8]);

    for i = 1:n
        idx = img_ids(i);
        fname = fullfile(folder, sprintf("Image_%d.tiff", idx));

        if isfile(fname)
            img = imread(fname);
            subplot(nrows, ncols, i);
            imshow(img, []);
            title(sprintf("Image_%d.tiff", idx), 'Interpreter','none');
        else
            warning("❌ File non trovato: %s", fname);
        end
    end
end

%/////////////////////////////////////////////////////
%               P A R A M E T E R S                  /
%/////////////////////////////////////////////////////

thr_appleX = 600;
thr_appleY = 600;
min_lengthX = 100;
min_lengthY = 50;

%/////////////////////////////////////////////////////
%                   M A I N                          /
%/////////////////////////////////////////////////////

%{
This code analysis the 0-4096 intensity of the test image folder
"test_images/apples_images". It assumes that an apple is given by a signal
which stands over a threshold both in the x-th and y-th directions for a
set "trigger time" (=#pixels). This does not prevent from recognizing false
apples, such as cuboid objects.
- roi_bounds_1D(): finds 1-dimensional ROI
- plot_single_roi(): can plot single profile in the x-th or y-th direction
- roi_bounds_image(): finds 2-dimensional ROI=(ROIx,ROIy)
- plot_crop_box(): plot a cropped image and the box around the found object 
- plot_box_only(): display only the bounded box in the figure
- plot_intensity_profiles(): basically use plot_single_roi() for getting slice
    of the image for a given step (e.g. step=50 -> one profile every 50px
    -> ca. 20 profiles in the x-th direction)
- batch_roi_from_folder(): prints all the 2-dimensional ROIs founded for
every image in the selected folder.
%}

% Loading image
path_folder = "CV@TR2/test_images/apples_images/"; 
img_id = input("Insert image id: ");
filename = "Image_" + img_id + ".tiff";
fullname = path_folder + filename;
fprintf('Analyzing file %s ...\n', fullname);
img_raw = imread(fullname);
imshow(img_raw,[]);

% Define restricted x-range to belt zone
title("Draw a horizontal line over the belt zone...");
h = drawline('Color','r','LineWidth',2);
points = round(h.Position);
left_x = min(points(:,1));
right_x = max(points(:,1));
fprintf("You selected zone: [%d,%d]\n", left_x, right_x);
x_range = [left_x, right_x];
%}

% ROIx e ROIy
typical_xrange = [360 750];
%[roi_x1, roi_x2] = roi_bounds_image(img_raw, thr_appleX, min_lengthX, 'x'); %364,742
[roi_y1, roi_y2] = roi_bounds_image(img_raw, thr_appleY, min_lengthY, 'y');
[roi_x1, roi_x2] = roi_bounds_image_2(img_raw, thr_appleX, min_lengthX, 'x', x_range);

% UNCOMMENT to RUN
%plot_single_roi(img_raw, roi_x1, roi_x2, 'x', 'Image_69.tiff');
%plot_single_roi(img_raw, roi_y1, roi_y2, 'y', 'Image_69.tiff');
%plot_crop_box(img_raw, roi_x1, roi_x2, roi_y1, roi_y2, sprintf("%s con x-range", filename));
%plot_box_only(img_raw, roi_x1, roi_x2, roi_y1, roi_y2, sprintf("%s con x-range", filename));
%step = 50; 
%plot_intensity_profiles_grid(img_raw, step); % prints once every step lines 
%my_results = readtable("CV@TR2\outputs\roi_results.csv");
%img_multiplots_roi(path_folder, my_results);
img_multiplots(1,50,100, path_folder);

close_all_figures();

%% TEST on multiple FILES

function results = batch_roi_from_folder(folder_path, threshold_x, threshold_y, min_length_x, min_length_y, x_range, output_folder)
    % Calcola ROIx (in range limitato) e ROIy (completo) per tutte le immagini
    % e salva un'immagine con bounding box per ciascuna.

    if nargin < 7
        error('Uso: batch_roi_from_folder(folder, thr_x, thr_y, min_len_x, min_len_y, x_range, output_folder)');
    end

    % Leggi i file TIFF
    image_files = dir(fullfile(folder_path, '*.tiff'));
    if isempty(image_files)
        error('❌ Nessuna immagine trovata nella cartella: %s', folder_path);
    end

    % Crea cartella output se non esiste
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end

    % Prealloca output
    N = length(image_files);
    file_names = strings(N, 1);
    roi_x1s = NaN(N, 1); roi_x2s = NaN(N, 1);
    roi_y1s = NaN(N, 1); roi_y2s = NaN(N, 1);

    fprintf('📂 Elaborazione cartella: %s\n\n', folder_path);

    for i = 1:N
        fname = image_files(i).name;
        fullpath = fullfile(folder_path, fname);

        try
            img = imread(fullpath);

            % ROIx con scan limitato a x_range
            disp(x_range)
            [roi_x1, roi_x2] = roi_bounds_image_2(img, threshold_x, min_length_x, 'x', x_range);

            % ROIy completa su tutte le colonne
            [roi_y1, roi_y2] = roi_bounds_image(img, threshold_y, min_length_y, 'y');

            % Salva dati
            file_names(i) = fname;
            roi_x1s(i) = roi_x1; roi_x2s(i) = roi_x2;
            roi_y1s(i) = roi_y1; roi_y2s(i) = roi_y2;

            % Plot e salva
            fig = figure('Visible', 'off');  % non mostrare a schermo
            plot_box_only(img, roi_x1, roi_x2, roi_y1, roi_y2, fname);
            %saveas(fig, fullfile(output_folder, [fname, '_roi.png']));
            close(fig);

            fprintf("✅ %s → ROIx = [%d, %d], ROIy = [%d, %d]\n", ...
                fname, roi_x1, roi_x2, roi_y1, roi_y2);

        catch ME
            fprintf("⚠️  %s → Errore: %s\n", fname, ME.message);
        end
    end

    % Tabella finale
    results = table(file_names, roi_x1s, roi_x2s, roi_y1s, roi_y2s, ...
        'VariableNames', {'Filename', 'ROI_X1', 'ROI_X2', 'ROI_Y1', 'ROI_Y2'});

    % Salva anche in CSV
    writetable(results, fullfile(output_folder, 'roi_results.csv'));
end

test_folder = "CV@TR2\test_images\apples_images";
output_folder = "CV@TR2\outputs";

typical_xrange = [360 750]; 
thr_appleX = 900;
thr_appleY = 900;
min_lengthX = 100;
min_lengthY = 50;

results = batch_roi_from_folder(test_folder, thr_appleX, thr_appleY, min_lengthX, min_lengthY, typical_xrange, output_folder);
close_all_figures();