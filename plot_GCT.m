% Parameters
cellSize = 40; % pixel size per heatmap cell
rows = 8; cols = 8;
imgHeight = rows * cellSize;
imgWidth = cols * cellSize;

% Initialize full image as white
heatmapImage = ones(imgHeight, imgWidth, 3);

gradientCells_forward = false(rows, cols);
gradientCells_forward(2, 6) = true; % green → blue

gradientCells_reverse = false(rows, cols);
gradientCells_reverse(5, 1) = true; % blue → green (example)

% Define start and end colors
startColor = hex2rgb('#1E803D'); % green
endColor   = hex2rgb('#6A9ACE'); % blue

for i = 1:rows
    for j = 1:cols
        r_start = (i - 1) * cellSize + 1;
        r_end   = i * cellSize;
        c_start = (j - 1) * cellSize + 1;

        val = data(i, j);
        if gradientCells_forward(i, j)
            for x = 0:cellSize-1
                t = x / (cellSize - 1); % left to right
                color = (1 - t) * startColor + t * endColor;
                heatmapImage(r_start:r_end, c_start + x, :) = repmat(reshape(color, 1, 1, 3), [cellSize, 1, 1]);
            end
        elseif gradientCells_reverse(i, j)
            for x = 0:cellSize-1
                t = x / (cellSize - 1); % right to left
                color = (1 - t) * endColor + t * startColor;
                heatmapImage(r_start:r_end, c_start + x, :) = repmat(reshape(color, 1, 1, 3), [cellSize, 1, 1]);
            end
        elseif isnan(val)
            % Fill NaN cell with gray (e.g., RGB = [0.65 0.65 0.65])
            grayColor = [0.65 0.65 0.65];
            heatmapImage(r_start:r_end, c_start:c_start + cellSize - 1, :) = ...
                repmat(reshape(grayColor, 1, 1, 3), [cellSize, cellSize, 1]);
        end
    end
end


% Show image
figure;
image(heatmapImage);
axis equal off;

% Load values
load Gamma_GCT.mat
data = pValue_gct;

% Overlay text
for i = 1:rows
    for j = 1:cols
        val = data(i, j);
        if isnan(val)
            label = 'NaN';
            weight = 'normal';
        else
            label = sprintf('%.3f', val);
            if val < 0.05
                weight = 'bold';
            else
                weight = 'normal';
            end
        end
        % Adjust text position to pixel coordinates
        x = (j - 0.5) * cellSize;
        y = (i - 0.5) * cellSize;
        text(x, y, label, 'HorizontalAlignment', 'center', ...
             'FontSize', 10, 'Color', 'k', 'FontWeight', weight);
    end
end

% Save
frame = getframe(gca);
imwrite(frame.cdata, 'Gamma_GCT_new.tif');

% Helper
function rgb = hex2rgb(hex)
    if hex(1) == '#'
        hex = hex(2:end);
    end
    rgb = reshape(sscanf(hex, '%2x') / 255, 1, 3);
end
