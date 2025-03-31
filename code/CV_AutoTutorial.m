
% 1) Basic Image Import, Processing, and Export

I = imread("pout.tif");
imshow(I) % show the image
title("L'immagine di una bambina")
pause(3); % keeps the canvas open for 3s
close; % close the current canvas
imhist(I) % show the intensity distribution

I2 = histeq(I); % transforms grayscale image so the histogram of the output has 64 bins and is approximately flat
imshow(I2)
title("L'immagine di una bambina - Contrasto Elevato")
imwrite(I2, "pout.png") % saves in same directory of this script

% 2) Detect and Measure Circular Objects in an Image

rgb = imread("coloredChips.png");
imshow(rgb)

d = drawline; % draw diameter on the image directly
pos = d.Position; % vettore [x1,y1;x2,y2]
diffPos = diff(pos); % (x2-x1, y2-y1)
diameter = hypot(diffPos(1),diffPos(2));

% PHASE CODING METHOD
gray_image = im2gray(rgb);
imshow(gray_image)
[centers, radii] = imfindcircles(rgb,[20 25], ObjectPolarity="dark"); % no circles found
[centers, radii] = imfindcircles(rgb,[20 25], ObjectPolarity="dark", Sensitivity=0.9); % increase Sensitivity to get more circles detected
imshow(rgb)
h = viscircles(centers,radii);
length(centers)
delete(h); % reset previous call

% TWO-STAGE METHOD
[centers, radii] = imfindcircles(rgb,[20 25],ObjectPolarity="dark",Sensitivity=0.92,Method="twostage");
delete(h)
h=viscircles(centers,radii) % visualize detected circles on canvas

% How to detect yellow chips
imgshow(gray_image)
[centersBright, radiiBright] = imfindcircles(rgb,[20 25],ObjectPolarity="bright",Sensitivity=0.92,Method="twostage");
hBright = viscircles(centersBright, radiiBright, Color="b"); % change border color of detected circles
hBright = viscircles(centersBright, radiiBright, 'LineStyle','--'); % change borders into dashed lines
[centersBright, radiiBright, metricBright] = imfindcircles(rgb,[20 25],ObjectPolarity="bright",Sensitivity=0.92,EdgeThreshold=0.1); % gradient threshold to distinguish edge pixels from non-edge pixels
delete(hBright)
hBright = viscircles(centersBright,radiiBright,Color="g");

% To catch 'em all
[centers, radii] = imfindcircles(rgb,[20 25],ObjectPolarity="dark",Sensitivity=0.92,Method="twostage");
h=viscircles(centers,radii, 'Color','m','LineStyle','--') 
[centersBright, radiiBright, metricBright] = imfindcircles(rgb,[20 25],ObjectPolarity="bright",Sensitivity=0.92,EdgeThreshold=0.1); % gradient threshold to distinguish edge pixels from non-edge pixels
hBright = viscircles(centersBright,radiiBright,'Color','b','LineStyle','--');

% 3) Correct Nonuniform Illumination and Analyze Foreground Objects

img = imread('rice.png');
imshow(img);
pause(3);
close;

% removing foreground with structuring elements and getting the clean image
% of the foreground
se = strel('disk',15);
background = imopen(img,se); % i) img with no foreground
imshow(background);
pause(3);
close;
img_nobkg = img - background; % ii) foreground with no bkg
imshow(img_nobkg); % it's now too dark for analysis
pause(3);
close;
img_clean = imadjust(img_nobkg); % iii) adjust contrast
imshow(img_clean)

img_clean_fast = imadjust(imtophat(img,strel('disk',15))); % as one line command

% get the binary image
img_bin = imbinarize(img_clean);
img_bin = bwareaopen(img_bin,50); % remove objects with less than 50px (area opening)
imshow(img_bin);
pause(3);
close;

% identify objects 
cc = bwconncomp(img_bin,4); % finds and counts connected component, can miscount touching objects; connectivity=4 -> adiacent px in vertical and horizontal, 8 -> also diagonal px,...
cc.NumObjects
grain_50th = false(size(img_bin)); % creates total black binary matrix same size of img_bin
grain_50th(cc.PixelIdxList{50}) = true; % extract 50th item from cc object
imshow(grain_50th)

lm = labelmatrix(cc); % transform cc into standard matrix object feasibile to label
whos lm
RGB_label = label2rgb(lm, 'spring','c','shuffle');
imshow(RGB_labell)

% compute area based statistics
grain_data = regionprops(cc,'basic'); %measures properties such as area, centroid, and bounding box, for each object (connected component) in an image
grain_areas = [grain_data.Area];
grain_50th_area = grain_areas(50);

[min_area_value, min_area_idx] = min(grain_areas);
grain_min_area = false(size(img_bin));
grain_min_area(cc.PixelIdxList{min_area_idx}) = true;
imshow(grain_min_area)

histogram(grain_areas)
title('Rice Area Distribution')

% TESTS for SINGLE CELLS RUN

%% Test - start executable section here
img_test = imread("saturn.png")
imshow(img_test)
pause(3);
close;

%% Test 2 - start another executable section here
img_test2 = imread("liftingbody.png")
imshow(img_test2)
pause(3);
close;

%% Test 3 - Rotate and Zoom an image
img_test3 = imread("strawberries.jpg");
angle = input('Insert angle: ');
zoom_factor = input ('Insert zoom factor: ');

img_test3_rotated = imrotate(img_test3, angle, 'bilinear','crop');
imshow(img_test3_rotated);
pause(3);
close;

[rows, cols, ~] = size(img_test3_rotated); % ignores channels number
fprintf('Rows: %d, Columns: %d\n', rows, cols)
cx = round(rows/2); 
cy = round(cols/2);
fprintf('Center of the image is: (%d,%d)', cx, cy);
zoomedWidth = round (cols/zoom_factor);
zoomedHeight = round (rows/zoom_factor);

% coordinates for centered crop
x1 = max(1, cx - floor(zoomedWidth/2));
x2 = min(cols, cx + floor(zoomedWidth/2)-1);
y1 = max(1, cy - floor(zoomedHeight/2));
y2 = min(rows, cy + floor(zoomedHeight/2)-1);

img_test3_zoomed = imresize(img_test3_rotated(y1:y2, x1:x2, :), [rows, cols]);

figure; % opens a new canvas
imshow(img_test3_zoomed);
title(sprintf("Rotazione: %d - Zoom: %.2f", angle, zoom_factor));


%% Visualize all predefined images
imageDir = fullfile(matlabroot, 'toolbox', 'images', 'imdata');
files = dir(fullfile(imageDir, '*.*'));
for k = 1:length(files)
    if ~files(k).isdir
        disp(files(k).name)
    end
end

%% Find Vegetation in a Multispectral Image
%{
This examples deals with 3D image array where the 3 planes represent signal
from different region of the EM spectrum; differences can be used to
distinguish surface features which have varying reflectivity response
across different spectral channels.
Here the difference between VISIBLE RED and NEAR-INFRARED (NIR) is made in
order to detect vegetation.
The file contains a 7-channels (bands) 512x512 Landsat image of a region in
Paris, France.
%}

%% Analyze an apple image
default_pause = 0.5; % seconds

filename = ('test_images/Image_75.tiff');
img_SWIR_test = imread(filename);
imshow(img_SWIR_test, []) % automatically adapt contrast
title("La mela")
d_obj = drawline; % draw diameter on the image directly
pos = d_obj.Position; % vettore [x1,y1;x2,y2]
diffPos = diff(pos); % (x2-x1, y2-y1)
d_ref = hypot(diffPos(1),diffPos(2));
area_ref = pi * (d_ref/2)^2;
fprintf("Reference diameter of an apple: %.2f px\n", d_value);
fprintf("Reference area of an apple: %.2f px\n", pi*(d_value/2)^2);

%pause(default_pause);
%close;

% Basic (unuseful) statistics
min_val = min(img_SWIR_test(:)); % 0
max_val = max(img_SWIR_test(:)); % 4095 -> correspond to 2^12, 12-bit encoding
mean_val = mean(img_SWIR_test(:)); % relatively low -> majority is bkg
std_val = std(double(img_SWIR_test(:))); % relaively high -> significant contrast

fprintf("Min: %d, Max: %d, Mean: %.2f, Std: %.2f\n", ...
         min_val, max_val, mean_val, std_val);

% Intensity histogram
histogram(img_SWIR_test(:), 512);  % 512 bin se è uint16
title('Pixels for given intensity');
xlabel('Intensity [a.u.]');
ylabel('Counts');
pause(default_pause);
close;

% Segmentation: separate objects from background
level = graythresh(img_SWIR_test);  % Otsu su img_SWIR_test normalizzata
img_SWIR_test_bin = imbinarize(mat2gray(img_SWIR_test), level);
imshow(img_SWIR_test_bin);
title("Binary segmentation");
pause(default_pause);
close;

% Object detection
area_tol = 0.2;
ecc_tol = 0.75;
connectivity = input('Insert connectivity (4-8 for 2D): ');
cc = bwconncomp(img_SWIR_test_bin, connectivity)
stats = regionprops(cc, img_SWIR_test,'Area', 'BoundingBox', 'Centroid','Perimeter','Eccentricity','Orientation','MeanIntensity','PixelValues');
  
all_areas = [stats.Area];
fprintf('Area minima: %.0f px\n', min(all_areas));
fprintf('Area massima: %.0f px\n', max(all_areas));
fprintf('Area media: %.2f px\n', mean(all_areas));
fprintf('Deviazione standard: %.2f px\n', std(all_areas));


% 1. Trova tutti i valori distinti
unique_areas = unique(all_areas);
% 2. Conta le occorrenze per ciascun valore
counts = histc(all_areas, unique_areas);
% 3. Crea l'istogramma discreto
figure;
bar(unique_areas, counts);
xlabel('Area [pixel]');
ylabel('Numero di oggetti');
title('Area distribution');
for i = 1:length(counts)
    if counts(i) > 0
        text(unique_areas(i), counts(i) + 1, num2str(counts(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 8);
    end
end

%pause(5);
%close;

disp('Starting loop...')

for id_mycc = 1:length(stats)

    % --- STEP 1: Geometrical filter ---
    obj_area = stats(id_mycc).Area;
    obj_ecc = stats(id_mycc).Eccentricity;
    area_ok = abs(obj_area - area_ref) / area_ref <= area_tol;
    ecc_ok = obj_ecc <= ecc_tol;
    if ~area_ok || ~ecc_ok % if filter fails, go to next object
        continue;
    end

    % --- STEP 2: Visualization of the object ---
    obj_mask = false(size(img_SWIR_test_bin));
    obj_mask(cc.PixelIdxList{id_mycc}) = true;

    % Find boundaries
    B = bwboundaries(obj_mask);
    boundary = B{1};  % ce n'è solo uno, perché la mask è di un singolo oggetto
    plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 1);

    % Visualizza l'immagine originale e disegna l’oggetto
    figure;
    imshow(img_SWIR_test, []);  % oppure imshow(obj_mask) per binario
    hold on;
   

    % Bounding Box
    rectangle('Position', stats(id_mycc).BoundingBox, ...
          'EdgeColor', 'g', 'LineWidth', 1);

    % Centroide
    plot(stats(id_mycc).Centroid(1), stats(id_mycc).Centroid(2), 'bo');

    % Mostra proprietà testuali
    text(stats(id_mycc).Centroid(1)+10, stats(id_mycc).Centroid(2), ...
        sprintf('Area: %.0f\nEcc: %.2f\nBoundingBox: %.2f\nMeanIntensity: %.2f', ...
                stats(id_mycc).Area, stats(id_mycc).Eccentricity, stats(id_mycc).BoundingBox),stats(id_mycc).MeanIntensity, ...
        'Color', 'yellow', 'FontSize', 9);

    title(sprintf('Oggetto #%d evidenziato', id_mycc));

    pause(default_pause);
    close;

end
disp('Loop finished.')

% Object detection

imshow(img_SWIR_test, []);
hold on;
for k = 1:length(stats)
    rectangle('Position', stats(k).BoundingBox, ...
              'EdgeColor', 'r', 'LineWidth', 1);
end
title(sprintf("Trovati %d oggetti", length(stats)));
pause(3);
close;


disp('here')