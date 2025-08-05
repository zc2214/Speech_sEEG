%% Data Processing Script for RegionDataTable_Merged
% Load the data files
load('SP2Ex2_SingleSubject_RSA.mat');
load('SubjectVoice_RT.mat');

fprintf('Loaded RegionDataTable_Merged: %d rows, %d columns\n', size(RegionDataTable_Merged));
fprintf('Loaded name_RT_table: %d subjects\n', size(name_RT_table, 1));

%% Step 1: Copy the specified columns (1, 2, 3, 4, 10, 17)
% Note: Excluding column 9 (Merged_Noise), using only column 10 (Merged_Signal)
% Timepoints array will be adjusted to match signal data length
% All sequences will be resampled to exactly 500 time points
selected_columns = [1, 2, 3, 4, 10, 17];

% Initialize table columns
n_rows = size(RegionDataTable_Merged, 1);
SubjectName = cell(n_rows, 1);
FrequencyRange = cell(n_rows, 1);
Task = cell(n_rows, 1);
ChannelName = cell(n_rows, 1);
Timepoints = cell(n_rows, 1);
MergedTimeSeries = cell(n_rows, 1);
ReactionTimes = cell(n_rows, 1);
ReactionTimeIndices = cell(n_rows, 1);
UniformChunkedData = cell(n_rows, 1);
TargetLength = zeros(n_rows, 1);

fprintf('Processing %d rows...\n', size(RegionDataTable_Merged, 1));

for row_idx = 1:size(RegionDataTable_Merged, 1)
    if mod(row_idx, 100) == 0
        fprintf('Processing row %d/%d\n', row_idx, size(RegionDataTable_Merged, 1));
    end
    
    % Extract the row data
    
    % Columns 1-4: strings
    SubjectName{row_idx} = RegionDataTable_Merged.SubjectName{row_idx};
    FrequencyRange{row_idx} = RegionDataTable_Merged.FrequencyRange{row_idx};
    Task{row_idx} = RegionDataTable_Merged.Task{row_idx};
    ChannelName{row_idx} = RegionDataTable_Merged.ChannelName{row_idx};
    
    % Column 10: Merged_Signal only (excluding Merged_Noise)
    merged_signal = RegionDataTable_Merged.Merged_Signal{row_idx};
    
    % Column 17: time points
    full_timepoints = RegionDataTable_Merged.Timepoints{row_idx};
    
    % Step 2: Use only Merged_Signal (column 10) and adjust timepoints accordingly
    % Each cell contains t_timepoints × n_trials time series
    if iscell(merged_signal) && ~isempty(merged_signal)
        MergedTimeSeries{row_idx} = merged_signal;
        
        % Get the number of timepoints in the signal data
        if ~isempty(merged_signal{1})
            signal_timepoints = size(merged_signal{1}, 1);
            % Extract corresponding timepoints (assuming signal corresponds to the last part)
            % Since noise (51) + signal (512) = total (563), signal starts at index 52
            noise_timepoints = length(full_timepoints) - signal_timepoints;
            if noise_timepoints >= 0 && noise_timepoints < length(full_timepoints)
                timepoints = full_timepoints((noise_timepoints + 1):end);
            else
                % Fallback: use all timepoints if calculation doesn't match
                timepoints = full_timepoints;
            end
        else
            timepoints = full_timepoints;
        end
    else
        MergedTimeSeries{row_idx} = [];
        timepoints = full_timepoints;
    end
    
    Timepoints{row_idx} = timepoints;
    
    % Step 3: Match with reaction time table
    subject_name = SubjectName{row_idx};
    rt_row_idx = find(strcmp(name_RT_table.Name, subject_name), 1);
    
    if ~isempty(rt_row_idx)
        reaction_times = name_RT_table.RT{rt_row_idx};
        ReactionTimes{row_idx} = reaction_times;
        
        % Step 4 & 5: Convert reaction times to time indices and chunk data
        if ~isempty(timepoints) && ~isempty(reaction_times) && ~isempty(MergedTimeSeries{row_idx})
            % Convert reaction times to time point indices
            rt_indices = zeros(size(reaction_times));
            for rt_idx = 1:length(reaction_times)
                [~, closest_idx] = min(abs(timepoints - reaction_times(rt_idx)));
                rt_indices(rt_idx) = closest_idx;
            end
            
            % Chunk each time series according to reaction time
            chunked_data = cell(size(MergedTimeSeries{row_idx}));
            target_length = 500; % Fixed target length of 500 time points
            
            for trial_idx = 1:length(MergedTimeSeries{row_idx})
                if trial_idx <= length(rt_indices) && ~isempty(MergedTimeSeries{row_idx}{trial_idx})
                    time_series = MergedTimeSeries{row_idx}{trial_idx};
                    rt_idx = rt_indices(trial_idx);
                    
                    % Chunk from start to reaction time
                    if rt_idx > 0 && rt_idx <= size(time_series, 1)
                        chunked_data{trial_idx} = time_series(1:rt_idx, :);
                    else
                        chunked_data{trial_idx} = time_series;
                    end
                else
                    chunked_data{trial_idx} = [];
                end
            end
            
            % Step 5: Sort reaction times and get sort indices
            [sorted_reaction_times, sort_indices] = sort(reaction_times);
            ReactionTimes{row_idx} = sorted_reaction_times;
            
            % Also sort the reaction time indices
            sorted_rt_indices = rt_indices(sort_indices);
            ReactionTimeIndices{row_idx} = sorted_rt_indices;
            
            % Step 6: Resample all sequences to exactly 500 time points
            % Downsample longer sequences, upsample shorter sequences
            uniform_chunked_data = cell(size(chunked_data));
            for trial_idx = 1:length(chunked_data)
                if ~isempty(chunked_data{trial_idx})
                    current_length = size(chunked_data{trial_idx}, 1);
                    n_trials = size(chunked_data{trial_idx}, 2);
                    
                    if current_length ~= target_length
                        % Resample to target_length (either downsample or upsample)
                        indices = linspace(1, current_length, target_length);
                        uniform_chunked_data{trial_idx} = zeros(target_length, n_trials);
                        
                        for trial_col = 1:n_trials
                            uniform_chunked_data{trial_idx}(:, trial_col) = ...
                                interp1(1:current_length, chunked_data{trial_idx}(:, trial_col), ...
                                       indices, 'linear', 'extrap');
                        end
                    else
                        % Already correct length
                        uniform_chunked_data{trial_idx} = chunked_data{trial_idx};
                    end
                    
                    % Apply consistent sorting across all trial groups
                    if n_trials <= length(sort_indices)
                        trial_sort_indices = sort_indices(1:n_trials);
                        uniform_chunked_data{trial_idx} = uniform_chunked_data{trial_idx}(:, trial_sort_indices);
                    end
                else
                    uniform_chunked_data{trial_idx} = [];
                end
            end
            
            UniformChunkedData{row_idx} = uniform_chunked_data;
            TargetLength(row_idx) = target_length;
        else
            ReactionTimeIndices{row_idx} = [];
            UniformChunkedData{row_idx} = [];
            TargetLength(row_idx) = target_length;
        end
    else
        fprintf('Warning: No reaction time found for subject %s\n', subject_name);
        ReactionTimes{row_idx} = [];
        ReactionTimeIndices{row_idx} = [];
        UniformChunkedData{row_idx} = [];
        TargetLength(row_idx) = target_length;
    end
end

%% Create Table and Save Results
fprintf('\nCreating table...\n');

% Create the table
processed_table = table(SubjectName, FrequencyRange, Task, ChannelName, ...
    Timepoints, MergedTimeSeries, ReactionTimes, ReactionTimeIndices, ...
    UniformChunkedData, TargetLength);

fprintf('Processing completed!\n');
fprintf('Total rows processed: %d\n', height(processed_table));

% Count successful matches
successful_matches = sum(~cellfun(@isempty, ReactionTimes));
fprintf('Successful RT matches: %d/%d\n', successful_matches, height(processed_table));

% Save the processed data as table
save('processed_aligned_data.mat', 'processed_table', '-v7.3');
fprintf('Results saved to: processed_aligned_data.mat (as table)\n');

%% Display example result
if height(processed_table) > 0
    fprintf('\nExample processed data (first row):\n');
    fprintf('Subject: %s\n', processed_table.SubjectName{1});
    fprintf('Channel: %s\n', processed_table.ChannelName{1});
    if ~isempty(processed_table.ReactionTimes{1})
        fprintf('Number of trials: %d\n', length(processed_table.ReactionTimes{1}));
        fprintf('Target length: %d time points\n', processed_table.TargetLength(1));
        if ~isempty(processed_table.UniformChunkedData{1}) && ~isempty(processed_table.UniformChunkedData{1}{1})
            fprintf('Resampled data size: %d timepoints x %d trials\n', ...
                size(processed_table.UniformChunkedData{1}{1}));
        end
    end
end
