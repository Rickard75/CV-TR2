function preprocess_SWIR(filename)
    fprintf("Analizzando file: %s\n", filename);
    img_raw = imread(filename);

    % Denoising
    img_denoised = medfilt2(img_raw, [3 3]);

    % Contrast enhancement
    img_contrast = imadjust(img_denoised, stretchlim(img_denoised), []);

    % Normalizzazione e CLAHE
    img_norm = mat2gray(img_contrast);
    img_clahe = adapthisteq(img_norm);

    % Edge detection
    edge_map = edge(img_norm, 'Canny');

    % Texture maps
    entropy_map = entropyfilt(img_denoised);
    range_map = rangefilt(img_denoised);
    std_local = stdfilt(img_denoised, ones(5));

    % === Visualizzazione comparativa ===
    figure('Name', sprintf('Preprocessing SWIR - %s', filename), 'NumberTitle', 'off');

    subplot(2, 4, 1);
    imshow(img_raw, []); title("Originale");

    subplot(2, 4, 2);
    imshow(img_denoised, []); title("Denoised");

    subplot(2, 4, 3);
    imshow(img_contrast, []); title("Contrast Stretched");

    subplot(2, 4, 4);
    imshow(img_clahe, []); title("CLAHE");

    subplot(2, 4, 5);
    imshow(edge_map); title("Edge - Canny");

    subplot(2, 4, 6);
    imshow(entropy_map, []); title("Entropy");

    subplot(2, 4, 7);
    imshow(range_map, []); title("Range");

    subplot(2, 4, 8);
    imshow(std_local, []); title("Std Local");

    % === Statistiche di base ===
    min_val = min(img_raw(:));
    max_val = max(img_raw(:));
    mean_val = mean(img_raw(:));
    std_val = std(double(img_raw(:)));

    fprintf("Min: %d, Max: %d, Mean: %.2f, Std: %.2f\n", ...
        min_val, max_val, mean_val, std_val);

    % Istogramma separato
    figure('Name', 'Istogramma Intensità');
    histogram(img_raw(:), 512);
    title('Intensità SWIR');
    xlabel('Intensità [a.u.]');
    ylabel('Pixel count');

    % FASE 7: Statistiche globali
    min_val = min(img_raw(:));
    max_val = max(img_raw(:));
    mean_val = mean(img_raw(:));
    std_val = std(double(img_raw(:)));

    fprintf("Min: %d, Max: %d, Mean: %.2f, Std: %.2f\n", ...
        min_val, max_val, mean_val, std_val);

    % Istogramma
    figure;
    histogram(img_raw(:), 512);
    title('Istogramma di intensità');
    xlabel('Intensità [a.u.]');
    ylabel('Numero di pixel');
end

%/////////////////////////////////////////////////////////
%                                                        /
%                       MAIN                             /
%                                                        /
%/////////////////////////////////////////////////////////



fileList = dir('test_images/*.tiff');

for k = 1:length(fileList)
    filename = fullfile(fileList(k).folder, fileList(k).name);
    preprocess_SWIR(filename);
    pause(1); % per evitare apertura immagini troppo rapida
end
