function inspect_spectral_image(filename)
    info = imfinfo(filename);
    num_frames = numel(info);

    fprintf("\nAnalisi del file: %s\n", filename);
    fprintf("Numero di frame/bande: %d\n", num_frames);

    img = imread(filename);
    dims = size(img);
    disp(['Dimensioni immagine: ', mat2str(dims)]);

    if ismatrix(img) && num_frames == 1
        fprintf("🟠 L'immagine è **monospettrale** (una sola banda SWIR).\n");

        figure;
        imshow(img, []);
        title('Immagine mono-spettrale');

    elseif ndims(img) == 3 && dims(3) <= 10
        fprintf("🔵 L'immagine è **multispettrale** (%d bande).\n", dims(3));

        % Prova a visualizzare un composito RGB se possibile
        if dims(3) >= 3
            img_rgb = img(:,:,1:3);
            img_rgb = mat2gray(img_rgb);  % Normalizzazione per visualizzazione
            figure;
            imshow(img_rgb);
            title('Composito RGB da bande multispettrali');
        end

    elseif num_frames > 10 || (ndims(img) == 3 && dims(3) > 10)
        fprintf("🟢 L'immagine è **ipoteticamente iperspettrale** (%d bande).\n", max(num_frames, dims(3)));
        fprintf("Ogni pixel contiene uno spettro fine.\n");

        % Visualizza spettri di esempio
        y = round(dims(1)/2); x = round(dims(2)/2);
        spectrum = squeeze(img(y, x, :));
        figure;
        plot(spectrum);
        title(sprintf('Spettro del pixel centrale (%d,%d)', x, y));
        xlabel('Banda'); ylabel('Intensità');

    else
        fprintf("⚠️ Immagine con struttura non standard. Controllare manualmente.\n");
    end
end

files = dir('test_images/*.tif');
for k = 1:length(files)
    inspect_spectral_image(fullfile(files(k).folder, files(k).name));
    pause(1);
end

