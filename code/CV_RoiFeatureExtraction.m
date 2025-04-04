%% ANALYSIS of INTENSITY: good apples VS evil apples

% === Parametri iniziali ===
csv_path = 'CV@TR2\test_images\apples_images\roi_results.csv';
image_folder = 'CV@TR2\test_images\apples_images';  % cartella immagini
intensity_threshold_low = 1000;   % soglia pixel scuri
intensity_threshold_high = 1500;  % soglia pixel luminosi

% === Leggi il CSV con le ROI ===
roi_data = readtable(csv_path);
results = table();
roi_skipped = 0;
roi_skipped_names = strings(0,1); % init

disp('Start extraction...')
for i = 1:height(roi_data)
    img_name = roi_data.Filename{i};
    img_path = fullfile(image_folder, img_name);
    
    % Controllo esistenza immagine
    if ~isfile(img_path)
        warning("Immagine non trovata: %s", img_path);
        continue;
    end
    
    % Caricamento immagine i-esima
    img = imread(img_path);
    img = double(img);  % per calcoli precisi
    
    % Coordinate ROI
    x1 = roi_data.ROI_X1(i);
    x2 = roi_data.ROI_X2(i);
    y1 = roi_data.ROI_Y1(i);
    y2 = roi_data.ROI_Y2(i);
    
    
    % Skip automatico se contiene NaN
    if any(isnan([x1, x2, y1, y2]))
        fprintf("Skipped image: %s: coordinate NaN\n",roi_data.Filename{i});
        roi_skipped = roi_skipped +1;
        roi_skipped_names(end+1) = string(img_name);
        continue;
    end
    
    % Estrazione ROI
    roi = img(y1:y2, x1:x2);
    roi_vect = roi(:); % flatten matrix into 1D columnwise vector
    
    % === Estrazione e salvataggio ROI estesa (con margine 20%) ===
    [img_h, img_w] = size(img);  % dimensioni dell'immagine
    roi_width = x2 - x1 + 1;
    roi_height = y2 - y1 + 1;

    % Calcolo del margine (20% delle dimensioni originali)
    margin_x = round(roi_width * 0.2);
    margin_y = round(roi_height * 0.2);

    % Nuove coordinate con margine
    x1_ext = max(1, x1 - margin_x);
    x2_ext = min(img_w, x2 + margin_x);
    y1_ext = max(1, y1 - margin_y);
    y2_ext = min(img_h, y2 + margin_y);

    % Estrai ROI estesa e salva l'immagine
    roi_extended = img(y1_ext:y2_ext, x1_ext:x2_ext);
    output_folder = fullfile(image_folder, 'apples_images_mroi');

    if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    end

    % Crea nome file di output
    [~, name, ~] = fileparts(img_name);
    out_img_name = sprintf('mroi_%s.png', name);
    % Normalizza il contrasto tra 0 e 255
    roi_norm = mat2gray(roi_extended);          % normalizza tra 0 e 1
    roi_scaled = uint8(roi_norm * 255);         % converti in uint8 per visualizzazione
    % Salva immagine
    imwrite(roi_scaled, fullfile(output_folder, out_img_name));


    % === Calcolo feature spettrali ===
    mean_int = mean(roi_vect);
    fprintf("Mean of %d is: %f\n", i, mean_int);
    std_int = std(roi_vect);
    min_int = min(roi_vect);
    max_int = max(roi_vect);
    median_int = median(roi_vect);
    range_int = max_int - min_int;
    iqr_val = iqr(roi_vect);
    p5 = prctile(roi_vect, 5);
    p95 = prctile(roi_vect, 95);
    
    % Distribuzione avanzata
    skew_val = skewness(roi_vect);
    %fprintf("Skewness of %d is: %f\n", i, skew_val);
    kurt_val = kurtosis(roi_vect);
    ent_val = entropy(mat2gray(roi));  % normalizzato 0-1 per entropy
    
    % Pixel estremi
    percent_low = sum(roi_vect < intensity_threshold_low) / numel(roi_vect);
    percent_high = sum(roi_vect > intensity_threshold_high) / numel(roi_vect);
    
    % Gini coefficient (diseguaglianza nella distribuzione)
    roi_sorted = sort(roi_vect);
    n = numel(roi_sorted);
    gini = (2*sum((1:n)'.*roi_sorted)/sum(roi_sorted) - (n + 1)) / n;
    
    % Mappa delle deviazioni locali (std su finestre 5x5)
    local_std_map = stdfilt(roi, true(5));
    local_std_mean = mean(local_std_map(:));
    
    % Gradienti locali (differenze verticali e orizzontali)
    [Gx, Gy] = gradient(roi);
    grad_mag = sqrt(Gx.^2 + Gy.^2);
    grad_mean = mean(grad_mag(:));
    grad_std = std(grad_mag(:));
    
    % === Salvataggio dei risultati ===
    results = [results; table({img_name}, x1, x2, y1, y2, ...
        mean_int, std_int, min_int, max_int, median_int, ...
        range_int, iqr_val, p5, p95, ...
        skew_val, kurt_val, ent_val, ...
        percent_low, percent_high, ...
        gini, local_std_mean, grad_mean, grad_std, ...
        'VariableNames', {'image_name','x1','x2','y1','y2', ...
        'mean_intensity','std_intensity','min_intensity','max_intensity','median_intensity', ...
        'range_intensity','iqr','percentile_5','percentile_95', ...
        'skewness','kurtosis','entropy', ...
        'percent_below_1000','percent_above_3000', ...
        'gini_coefficient','local_std_mean','gradient_mean','gradient_std'})];
end

% === Salva su file CSV ===
writetable(results, 'CV@TR2\test_images\apples_images\apples_images_mroi\mroi_features.xlsx');
fprintf("❌ Number of images invalid: %d\n", roi_skipped);
for i=1:length(roi_skipped_names)
    fprintf("%s\n", roi_skipped_names(i));
end
%disp("✅ Estrazione completata. File salvato: roi_features_full.csv");
