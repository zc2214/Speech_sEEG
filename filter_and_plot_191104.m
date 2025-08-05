%% Filter and Plot Script for 191104 Subjects
% Load processed data, filter for subjects starting with "191104" and areas of interest
% Generate heatmaps by channel ranked by reaction time

fprintf('Loading original data...\n');
load('SP2Ex2_SingleSubject_RSA.mat');
load('SubjectVoice_RT.mat');

fprintf('Original table size: %d rows, %d columns\n', size(RegionDataTable_Merged));

%% Define areas of interest (same as in plot_heatmaps.m)
areas_of_interest = {
    'pars opercularis - L',
    'pars opercularis - inferior L', 
    'pars opercularis - superior L',
    'superior temporal gyrus - posterior L'
};

%% Filter data for subjects starting with "191104" and areas of interest
fprintf('Filtering data for subjects starting with "191104"...\n');

% Find rows where subject name starts with "191104"
subject_filter = startsWith(RegionDataTable_Merged.SubjectName, '191104');
fprintf('Found %d rows for subjects starting with "191104"\n', sum(subject_filter));

% Find rows where channel name matches areas of interest
channel_filter = false(height(RegionDataTable_Merged), 1);
for i = 1:height(RegionDataTable_Merged)
    channel_name = RegionDataTable_Merged.ChannelName{i};
    for j = 1:length(areas_of_interest)
        if strcmp(channel_name, areas_of_interest{j})
            channel_filter(i) = true;
            break;
        end
    end
end
fprintf('Found %d rows for areas of interest\n', sum(channel_filter));

% Combine filters
combined_filter = subject_filter & channel_filter;
filtered_table = RegionDataTable_Merged(combined_filter, :);

fprintf('Filtered table size: %d rows\n', height(filtered_table));

if height(filtered_table) == 0
    fprintf('No data found matching criteria. Exiting.\n');
    return;
end

%% Create heatmap subfolder
if ~exist('heatmap_191104', 'dir')
    mkdir('heatmap_191104');
end

%% Generate heatmaps by channel
fprintf('\nGenerating heatmaps by channel...\n');

% Get unique channels
unique_channels = unique(filtered_table.ChannelName);
fprintf('Found %d unique channels: %s\n', length(unique_channels), strjoin(unique_channels, ', '));

for channel_idx = 1:length(unique_channels)
    channel_name = unique_channels{channel_idx};
    fprintf('\nProcessing channel: %s\n', channel_name);
    
    % Get all rows for this channel
    channel_rows = filtered_table(strcmp(filtered_table.ChannelName, channel_name), :);
    fprintf('  Found %d rows for this channel\n', height(channel_rows));
    
    % Process each trial group separately
    trial_group_count = 0;
    
    for row_idx = 1:height(channel_rows)
        % Get Merged_Signal data (column 10)
        merged_signal = channel_rows.Merged_Signal{row_idx};
        subject_name = channel_rows.SubjectName{row_idx};
        
        % Find reaction times for this subject
        rt_row_idx = find(strcmp(name_RT_table.Name, subject_name), 1);
        
        if ~isempty(merged_signal) && iscell(merged_signal) && ~isempty(rt_row_idx)
            reaction_times = name_RT_table.RT{rt_row_idx};
            
            % Process each trial group from this subject
            for trial_group_idx = 1:length(merged_signal)
                % Get both noise and signal data
                merged_noise = channel_rows.Merged_Noise{row_idx};
                merged_signal = channel_rows.Merged_Signal{row_idx};
                
                if ~isempty(merged_noise) && iscell(merged_noise) && trial_group_idx <= length(merged_noise)
                    noise_data = merged_noise{trial_group_idx};
                else
                    noise_data = [];
                end
                
                if ~isempty(merged_signal) && iscell(merged_signal) && trial_group_idx <= length(merged_signal)
                    signal_data = merged_signal{trial_group_idx};
                else
                    signal_data = [];
                end
                
                % Combine noise and signal data
                if ~isempty(noise_data) && ~isempty(signal_data) && isnumeric(noise_data) && isnumeric(signal_data)
                    % Concatenate noise and signal along time dimension
                    combined_data = [noise_data; signal_data];
                elseif ~isempty(signal_data) && isnumeric(signal_data)
                    combined_data = signal_data;
                elseif ~isempty(noise_data) && isnumeric(noise_data)
                    combined_data = noise_data;
                else
                    combined_data = [];
                end
                
                if ~isempty(combined_data) && size(combined_data, 2) == 50
                    trial_group_count = trial_group_count + 1;
                    
                    % Get timepoints and frequency range for this row
                    timepoints = channel_rows.Timepoints{row_idx};
                    frequency_range = channel_rows.FrequencyRange{row_idx};
                    
                    % Sort trials by reaction time for this specific subject
                    if ~isempty(rt_row_idx) && trial_group_idx <= length(reaction_times)
                        % Get reaction times for this trial group
                        trial_rts = reaction_times(1:50);
                        
                        % Sort trials by reaction time (short to long)
                        [sorted_rts, sort_indices] = sort(trial_rts);
                        
                        % Apply sorting to the trial data
                        sorted_trial_data = combined_data(:, sort_indices);
                    else
                        sorted_trial_data = combined_data;
                        sort_indices = 1:50;
                        sorted_rts = reaction_times(1:50);
                    end
                    
                    % Create figure for this individual trial group
                    figure('Position', [100, 100, 800, 600]);
                    
                    % Plot heatmap: transpose to get 50 trials (y-axis) × time points (x-axis)
                    imagesc(sorted_trial_data'); % Transpose to get trials on y-axis, time on x-axis
                    
                    % Set color scale from -3 to 3
                    clim([-3, 3]);
                    colorbar;
                    
                    % Get the actual time dimension
                    time_dim = size(sorted_trial_data, 1);
                    
                    % Labels and title
                    xlabel('Time (ms)', 'FontSize', 11);
                    ylabel('Trials (1-50, Fast to Slow)', 'FontSize', 11);
                    
                    % Set x-axis ticks using real timepoints
                    if ~isempty(timepoints) && length(timepoints) >= time_dim
                        % Use all timepoints (noise + signal)
                        all_timepoints = timepoints;
                        
                        % Find indices for specific time points: 0, 200, 400, 800
                        target_times = [0, 200, 400, 800];
                        tick_indices = [];
                        tick_times = [];
                        
                        for t = 1:length(target_times)
                            [~, idx] = min(abs(all_timepoints - target_times(t)));
                            if idx <= time_dim
                                tick_indices = [tick_indices, idx];
                                tick_times = [tick_times, all_timepoints(idx)];
                            end
                        end
                        
                        % Set ticks
                        if ~isempty(tick_indices)
                            xticks(tick_indices);
                            xticklabels(arrayfun(@(x) sprintf('%.0f', x), tick_times, 'UniformOutput', false));
                        end
                    else
                        % Fallback to time point indices if timepoints not available
                        if time_dim > 10
                            xticks([1, round(time_dim/4), round(time_dim/2), round(3*time_dim/4), time_dim]);
                            xticklabels({num2str(1), num2str(round(time_dim/4)), num2str(round(time_dim/2)), ...
                                        num2str(round(3*time_dim/4)), num2str(time_dim)});
                        end
                    end
                    
                    % Set colormap
                    colormap('jet');
                    
                    % Adjust axes
                    axis xy; % Ensure y-axis is in correct direction
                    
                    % Add reaction time markers for each trial
                    if ~isempty(rt_row_idx) && trial_group_idx <= length(reaction_times)
                        hold on;
                        
                        % Find the corresponding time indices in the full timepoints
                        if ~isempty(timepoints) && length(timepoints) >= time_dim
                            all_timepoints = timepoints;
                            
                            % Draw individual vertical line for each trial's reaction time
                            for trial_num = 1:min(50, length(sorted_rts))
                                rt_time = sorted_rts(trial_num);
                                [~, rt_idx] = min(abs(all_timepoints - rt_time));
                                
                                % Draw vertical line at this trial's reaction time (thicker line)
                                plot([rt_idx, rt_idx], [trial_num-0.5, trial_num+0.5], 'k-', 'LineWidth', 3);
                            end
                        end
                        
                        hold off;
                    end
                    

                    
                    % Create filename
                    channel_clean = regexprep(channel_name, '[^\w\-]', '_');
                    subject_clean = regexprep(subject_name, '[^\w\-]', '_');
                    freq_clean = regexprep(frequency_range, '[^\w\-]', '_');
                    filename = sprintf('191104_%s_%s_%s_trialgroup%d', channel_clean, freq_clean, subject_clean, trial_group_idx);
                    
                    % Save figure
                    filepath = fullfile('heatmap_191104', [filename '.tif']);
                    fprintf('  Saving figure as %s...\n', filepath);
                    saveas(gcf, filepath);
                    
                    % Close figure to free memory
                    close(gcf);
                    
                else
                    fprintf('  Warning: Trial group %d from subject %s has unexpected data size: %s\n', ...
                        trial_group_idx, subject_name, mat2str(size(trial_group_data)));
                end
            end
        end
    end
    
    fprintf('  Created %d individual trial group heatmaps for channel %s\n', trial_group_count, channel_name);
end

%% Summary
fprintf('\n=== Summary ===\n');
fprintf('Processed %d channels\n', length(unique_channels));
fprintf('All figures saved in heatmap_191104/ folder\n');
fprintf('Data filtered for subjects starting with "191104"\n');
fprintf('Areas of interest: %s\n', strjoin(areas_of_interest, ', '));

fprintf('\nFiltering and plotting completed!\n'); 