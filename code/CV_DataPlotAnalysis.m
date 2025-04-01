%% DATA ANALYSIS reading from EXTRACTED FEATURES

%/////////////////////////////////////////////////////
%               F U N C T I O N S
%/////////////////////////////////////////////////////

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

function T = analyze_features(T)
    
    % boxplots
    figure;
    boxplot(T.mean_intensity);
    title("Boxplot- Mean Intensity");
    
    figure;
    boxplot(T.entropy);
    title("Boxplot - Entropy");

    figure;
    boxplot(T.gradient_mean);
    title("Boxplot - Gradient Mean");

    % scatter 2D
    figure;
    scatter(T.mean_intensity, T.entropy, 40, 'filled');
    xlabel("Mean Intensity");
    ylabel("Entropy");
    title("Mean Intensity vs Entropy");

    figure;
    scatter(T.gradient_mean, T.percent_above_3000, 40, 'filled');
    xlabel("Gradient Mean");
    ylabel("Percent Pixels > 3000");
    title("Gradient vs % Pixel sopra 3000");
    
    % heatmap correlations
    figure;
    corrMatrix = corr(T{:,6:end}, 'rows','complete');
    heatmap(T.Properties.VariableNames(6:end), T.Properties.VariableNames(6:end), ...
        corrMatrix, 'Colormap', parula, 'ColorbarVisible', 'on');
    title("Heatmap delle Correlazioni");

    % empirical classification
    T.label = classify_apples_simple(T);

    % class scatter
    figure;
    gscatter(T.mean_intensity, T.entropy, T.label, 'br', 'xo');
    xlabel("Mean Intensity");
    ylabel("Entropy");
    title("Classificazione: Buone vs Cattive");

    % PARALLEL COORDINATES PLOT
    figure;
    parallelcoords(T{:, {'mean_intensity', 'entropy', 'percent_above_3000', 'gradient_mean'}}, ...
        'Group', T.label);
    title("Parallel Coordinates Plot");
end

% Funzione ausiliaria per classificazione
function labels = classify_apples_simple(T)
    labels = strings(height(T), 1);
    labels(T.mean_intensity > 1500 & T.entropy > 6 & T.percent_above_3000 > 0.6) = "buona";
    labels(labels == "") = "cattiva";
end


%/////////////////////////////////////////////////////
%                   M A I N                          /
%/////////////////////////////////////////////////////


T = readtable("CV@TR2/test_images/apples_images/apples_images_mroi/mroi_features.xlsx");
T = analyze_features(T);
writetable(T, "CV@TR2/test_images/apples_images/apples_images_mroi/mroi_labeled_features.xlsx")
close_all_figures();