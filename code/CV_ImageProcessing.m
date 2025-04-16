%% FIRST TRIAL

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

% Loading image
path_folder = "../test_images/apples_images/"; 
img_id = input("Insert image id: ");
filename = "Image_" + img_id + ".tiff";
fullname = path_folder + filename;
fprintf('Analyzing file %s ...\n', fullname);

% Simple display
figure;
img_raw = imread(fullname);
imshow(img_raw,[]);
title("A simple apple")

% Process matrix data
img_mat = mat2gray(img_raw); % sets values in range [0:1]
img_adj = imadjust(img_raw); % adjust contrast

figure;
imhist(img_adj)
title("Adjusted histogram")

figure;
imshowpair(img_raw, img_adj, "montage");
title("Before and after adjustment")

figure;
imshow(apple77_clear);
title("Segmented image of apple 77")
close_all_figures();

%% AUTOMATIC SEGMENTATION for 1 image

% Loading image
path_folder = "CV@TR2/test_images/apples_images/"; 
img_id = input("Insert image id: ");
filename = "Image_" + img_id + ".tiff";
fullname = path_folder + filename;
fprintf('Analyzing file %s ...\n', fullname);

threshold_value = 800;

% ==== 1. Lettura immagine ====
img_raw = imread(fullname);

% ==== 2. Segmentazione ====
img_bin = img_raw > threshold_value;

% ==== 3. Rimozione oggetti al bordo ====
img_bin_clean = imclearborder(img_bin);

% ==== 4. Applica la maschera mantenendo le intensità originali ====
img_masked = img_raw;               % copia
img_masked(~img_bin_clean) = 0; % metti a 0 fuori dalla maschera

% ==== 5. Adatta il contrasto ====
img_adj = imadjust(img_masked);

% ==== 6. Visualizza ====
figure;
imshow(img_adj, []);
title("Masked and contrast-adjusted image");

% ==== 7. Crea cartella di output ====
output_folder = 'CV@TR2/test_images/apples_images_clear/';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% ==== 8. Salva l’immagine mascherata ====
[~, name, ext] = fileparts(filename);
output_name = fullfile(output_folder, name + "_clear" + ext);
imwrite(img_adj, output_name);

fprintf("Immagine salvata in: %s\n", output_name);

close_all_figures();

%% AUTOMATIC SEGMENTATION for MULTIPLE IMAGES

function segment_batch_apples(input_folder, output_folder, threshold_value)

    % Create output folder
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end

    % Tiff files list
    files = dir(fullfile(input_folder, '*.tiff'));

    fprintf('Found %d images. Start segmentation...\n', length(files));

    for k = 1:length(files)
        filename = files(k).name;
        fullname = fullfile(input_folder, filename);
        
        % segmentation
        img = imread(fullname);
        img_bin = img > threshold_value;
        img_bin_clean = imclearborder(img_bin);
        
        % visualization
        img_masked = img;
        img_masked(~img_bin_clean) = 0;
        img_adj = imadjust(img_masked);

        % save
        [~, name, ext] = fileparts(filename);
        output_name = fullfile(output_folder, name + "_clear" + ext);
        imwrite(img_adj, output_name);

        fprintf('Saved: %s\n', output_name);
    end

    fprintf("Segmentation completed for folder %s",input_folder);
end

segment_batch_apples("CV@TR2/test_images/apples_images/","CV@TR2/test_images/apples_images/apples_images_clean_thr700/",700);

%% ADVANCED SEGMENTATION & FEATURE EXTRACTION

function segment_apples_auto(input_folder, output_folder)

    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end

    files = dir(fullfile(input_folder, '*.tiff'));
    fprintf("Found %d images in %s\n", length(files), input_folder);

    for k = 1:length(files)
        fullname = fullfile(input_folder, files(k).name);
        img = imread(fullname);
        img = double(img);  % 256 x 1024, grayscale

        [H, W] = size(img);

        % Verifica che larghezza sufficiente
        if W < 750
            warning("Immagine %s troppo stretta: W=%d < 750", files(k).name, W);
            continue;
        end

        % Crop su COLONNE centrali (360:750), manteniamo tutte le righe
        img_crop = img(:, 360:750);  % 256 x 391

        % Soglia automatica basata su percentile
        threshold = prctile(img_crop(:), 85);
        bw = img_crop > threshold;  % 256 x 391

        % Pulizia morfologica
        bw = bwareaopen(bw, 1000);

        % Maschera finale di dimensioni originali
        bw_full = false(H, W);         % 256 x 1024
        bw_full(:, 360:750) = bw;      % CORRETTO

        % Applica maschera all’immagine originale
        img_masked = img;
        img_masked(~bw_full) = 0;

        % Regola contrasto e salva
        img_adj = imadjust(uint16(img_masked));
        [~, name, ext] = fileparts(files(k).name);
        outname = fullfile(output_folder, name + "_thrP85" + ext);
        imwrite(img_adj, outname);

        fprintf("Saved: %s\n", outname);
    end

    fprintf("✅ Segmentazione completata su %s.\n", input_folder);
end

segment_apples_auto("CV@TR2/test_images/apples_images/", ...
                    "CV@TR2/test_images/apples_images/apples_images_clean_auto/");

function extract_features_apples(input_folder, output_csv)
    files = dir(fullfile(input_folder, '*.tiff'));
    data = [];

    fprintf('Found %d images to process...\n', length(files));

    for k = 1:length(files)
        fname = fullfile(input_folder, files(k).name);
        img = imread(fname);

        % Converti in double e normalizza
        img_dbl = double(img);
        img_dbl = mat2gray(img_dbl) * 4095; % Riporta a scala originale

        % Segmentazione base (rimuove background nero)
        bw = img_dbl > 50;  % Soglia minima, da regolare
        bw = imopen(bw, strel('disk', 3));
        bw = bwareafilt(bw, 1);  % Prende l’oggetto più grande (mela)
        
        [H, W] = size(img_dbl);  % dimensioni dell'immagine
        props = regionprops(bw, 'BoundingBox');

        if isempty(props)
            continue; % Nessuna ROI trovata
        end

        box = round(props(1).BoundingBox);
        x1 = max(1, box(1)); 
        y1 = max(1, box(2)); 
        w = box(3); 
        h = box(4);
        x2 = min(W, x1 + w - 1);  % Assicurati che non superi larghezza
        y2 = min(H, y1 + h - 1);  % Assicurati che non superi altezza

        % ROI e maschera
        roi = img_dbl(y1:y2, x1:x2); % rows from y1 to y2; columns from x1 to x2
        mask = bw(y1:y2, x1:x2);
        roi_masked = roi;
        roi_masked(~mask) = NaN;

        % Feature base
        pix = roi_masked(~isnan(roi_masked));
        mean_int = mean(pix);
        std_int = std(pix);
        min_int = min(pix);
        max_int = max(pix);
        median_int = median(pix);
        percentiles = prctile(pix, [10 25 50 75 90 95]);

        % Skewness e kurtosis
        sk = skewness(pix);
        ku = kurtosis(pix);

        % Entropia
        ent = entropy(uint16(pix));

        % Percentuali
        pct_below_1000 = sum(pix < 1000) / numel(pix);
        pct_above_3000 = sum(pix > 3000) / numel(pix);

        % Gini coefficient
        sorted_pix = sort(pix);
        n = numel(pix);
        G = 1 - (2 / (n - 1)) * (n - sum((n + 1 - (1:n)) .* sorted_pix') / sum(sorted_pix));

        % Gradienti
        [Gx, Gy] = gradient(roi_masked);
        Gmag = sqrt(Gx.^2 + Gy.^2);
        grad_mean = nanmean(Gmag(:));
        grad_std = nanstd(Gmag(:));

        % Std locale
        local_std = stdfilt(roi_masked, ones(3));
        local_std_mean = nanmean(local_std(:));

        % Salvataggio riga
        data = [data; {
            files(k).name, x1, x2, y1, y2, ...
            mean_int, std_int, min_int, max_int, median_int, ...
            percentiles(1), percentiles(2), percentiles(3), percentiles(4), percentiles(5), percentiles(6), ...
            sk, ku, ent, ...
            pct_below_1000, pct_above_3000, ...
            G, local_std_mean, grad_mean, grad_std
        }];
    end

    % Nomi colonne
    columns = {'image_name', 'x1','x2','y1','y2','mean_intensity','std_intensity', ...
        'min_intensity','max_intensity','median_intensity', ...
        'percentile_10','percentile_25','percentile_50','percentile_75','percentile_90','percentile_95', ...
        'skewness','kurtosis','entropy','percent_below_1000','percent_above_3000', ...
        'gini_coefficient','local_std_mean','gradient_mean','gradient_std'};

    % Scrittura CSV
    T = cell2table(data, 'VariableNames', columns);
    writetable(T, output_csv, 'FileType','spreadsheet');
    
    fprintf("✅ Feature extraction complete. CSV saved to: %s\n", output_csv);
end

% Automatic segmentation
extract_features_apples("CV@TR2/test_images/apples_images/apples_images_clean_auto/", ...
                        "CV@TR2/test_images/apples_images/apples_images_clean_auto/segmented_features.xlsx");
% Manual segmentation
extract_features_apples("CV@TR2/test_images/apples_images/apples_images_clean_thr800", ...
                        "CV@TR2/test_images/apples_images/apples_images_clean_thr800/features_clean_thr800.xlsx")
