%% Plot Heatmaps Script
% Load merged table, average across subjects, and plot heatmaps for specific rows
% Heatmaps will be 50 trials × 500 time points

fprintf('Loading merged table...\n');
load('merged_aligned_data.mat', 'merged_table');

fprintf('Merged table size: %d rows\n', height(merged_table));

%% Specify rows to plot
target_rows = [121, 127, 160, 196, 203, 223, 229, 262, 298, 305];
target_length = 500;

% Check if all target rows exist
valid_rows = target_rows(target_rows <= height(merged_table));
if length(valid_rows) < length(target_rows)
    fprintf('Warning: Some target rows exceed table size. Plotting available rows only.\n');
    fprintf('Available rows: %s\n', mat2str(valid_rows));
end

%% Process each target row and create individual figures
for plot_idx = 1:length(valid_rows)
    row_num = valid_rows(plot_idx);
    
    fprintf('Processing row %d (%d/%d)...\n', row_num, plot_idx, length(valid_rows));
    
    % Get the UniformChunkedData for this row
    uniform_data = merged_table.UniformChunkedData{row_num};
    
    if isempty(uniform_data)
        fprintf('Warning: No data found for row %d\n', row_num);
        continue;
    end
    
    fprintf('  Found %d trial groups for row %d\n', length(uniform_data), row_num);
    
    % Average across all trial groups (now concatenated from all subjects)
    averaged_data = [];
    valid_trial_groups = 0;
    
    for trial_group_idx = 1:length(uniform_data)
        trial_group_data = uniform_data{trial_group_idx};
        
        if ~isempty(trial_group_data) && isnumeric(trial_group_data)
            if size(trial_group_data, 1) == target_length && size(trial_group_data, 2) == 50
                if isempty(averaged_data)
                    averaged_data = trial_group_data;
                else
                    averaged_data = averaged_data + trial_group_data;
                end
                valid_trial_groups = valid_trial_groups + 1;
            else
                fprintf('  Warning: Trial group %d has unexpected data size: %s\n', ...
                    trial_group_idx, mat2str(size(trial_group_data)));
            end
        end
    end
    
    if valid_trial_groups > 0
        % Average across all trial groups
        averaged_data = averaged_data / valid_trial_groups;
        fprintf('  Averaged across %d trial groups\n', valid_trial_groups);
        
        % Create individual figure for this heatmap
        figure('Position', [100, 100, 800, 600]);
        
        % Plot heatmap: transpose to get 50 trials (y-axis) × 800 time points (x-axis)
        imagesc(averaged_data'); % Transpose to get trials on y-axis, time on x-axis
        
        % Set color scale from -3 to 3
        clim([-3, 3]);
        colorbar;
        
        % Labels and title
        % Set proper time labels (negative to zero)
        xlabel('Time (ms relative to reaction)', 'FontSize', 11);
        
        % Set x-axis ticks to show negative time scale
        xticks([1, target_length/4, target_length/2, 3*target_length/4, target_length]);
        xticklabels({sprintf('-%d', target_length), sprintf('-%d', 3*target_length/4), ...
                    sprintf('-%d', target_length/2), sprintf('-%d', target_length/4), '0'});
        
        % Set colormap
        colormap('jet');
        
        % Adjust axes
        axis xy; % Ensure y-axis is in correct direction
        
        % Create filename based on ChannelName + FrequencyRange
        channel_name = merged_table.ChannelName{row_num};
        freq_range = merged_table.FrequencyRange{row_num};
        
        % Clean up filename (remove invalid characters)
        channel_clean = regexprep(channel_name, '[^\w\-]', '_');
        freq_clean = regexprep(freq_range, '[^\w\-]', '_');
        filename = sprintf('%s_%s', channel_clean, freq_clean);
        
        % Create heatmap subfolder if it doesn't exist
        if ~exist('heatmap', 'dir')
            mkdir('heatmap');
        end
        
        % Save individual figure
        filepath = fullfile('heatmap', [filename '.tif']);
        fprintf('  Saving figure as %s...\n', filepath);
        saveas(gcf, filepath);
        
        % Close figure to free memory
        close(gcf);
        
    else
        fprintf('  Warning: No valid data found for row %d\n', row_num);
    end
end

%% Summary
fprintf('\nAll figures saved individually!\n');

%% Display summary statistics
fprintf('\nSummary Statistics:\n');
for plot_idx = 1:length(valid_rows)
    row_num = valid_rows(plot_idx);
    uniform_data = merged_table.UniformChunkedData{row_num};
    
    if ~isempty(uniform_data)
        fprintf('Row %d (%s - %s - %s): %d trial groups\n', ...
            row_num, ...
            merged_table.FrequencyRange{row_num}, ...
            merged_table.Task{row_num}, ...
            merged_table.ChannelName{row_num}, ...
            length(uniform_data));
    end
end

fprintf('\nHeatmap plotting completed!\n'); 