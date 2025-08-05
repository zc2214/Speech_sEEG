%% Merge Table Script
% Load the processed table and merge according to FrequencyRange, Task, and ChannelName
% Remove specified columns and rename SubjectName to UniversalSubject

fprintf('Loading processed table...\n');
load('processed_aligned_data.mat', 'processed_table');

fprintf('Original table size: %d rows, %d columns\n', height(processed_table), width(processed_table));

%% Remove specified columns (5, 7, 8, 10)
% Column 5: Timepoints
% Column 7: ReactionTimes  
% Column 8: ReactionTimeIndices
% Column 10: TargetLength

% Keep only the desired columns: 1, 2, 3, 4, 6, 9
kept_columns = {'SubjectName', 'FrequencyRange', 'Task', 'ChannelName', ...
                'MergedTimeSeries', 'UniformChunkedData'};

reduced_table = processed_table(:, kept_columns);
fprintf('After removing columns: %d rows, %d columns\n', height(reduced_table), width(reduced_table));

%% Standardize channel names for merging
fprintf('Standardizing channel names...\n');
standardized_channels = cell(height(reduced_table), 1);

for i = 1:height(reduced_table)
    channel_name = reduced_table.ChannelName{i};
    
    % Apply channel name mapping rules
    if contains(channel_name, 'pars opercularis - inferior L') || contains(channel_name, 'pars opercularis - superior L')
        standardized_channels{i} = 'pars opercularis - L';
    else
        standardized_channels{i} = channel_name;
    end
end

% Replace the original channel names with standardized ones
reduced_table.ChannelName = standardized_channels;
fprintf('Channel names standardized.\n');

%% Group by FrequencyRange, Task, and ChannelName
fprintf('Grouping by FrequencyRange, Task, and ChannelName...\n');

% Create a grouping key by combining the three columns
grouping_keys = strcat(reduced_table.FrequencyRange, '_', ...
                      reduced_table.Task, '_', ...
                      reduced_table.ChannelName);

% Find unique combinations
[unique_keys, ~, group_indices] = unique(grouping_keys);
n_groups = length(unique_keys);

fprintf('Found %d unique combinations\n', n_groups);

%% Create merged table
fprintf('Creating merged table...\n');

% Initialize arrays for the merged table
UniversalSubject = cell(n_groups, 1);
FrequencyRange = cell(n_groups, 1);
Task = cell(n_groups, 1);
ChannelName = cell(n_groups, 1);
MergedTimeSeries = cell(n_groups, 1);
UniformChunkedData = cell(n_groups, 1);

% Process each group
for group_idx = 1:n_groups
    if mod(group_idx, 10) == 0
        fprintf('Processing group %d/%d\n', group_idx, n_groups);
    end
    
    % Find all rows belonging to this group
    group_rows = find(group_indices == group_idx);
    
    % Take the first row's metadata (they should be the same within group)
    first_row = group_rows(1);
    UniversalSubject{group_idx} = 'UniversalSubject';  % Rename as requested
    FrequencyRange{group_idx} = reduced_table.FrequencyRange{first_row};
    Task{group_idx} = reduced_table.Task{first_row};
    ChannelName{group_idx} = reduced_table.ChannelName{first_row};
    
    % Merge data from all subjects in this group
    group_merged_series = {};
    group_uniform_data = {};
    
    for i = 1:length(group_rows)
        row_idx = group_rows(i);
        
        % Collect MergedTimeSeries from this subject
        if ~isempty(reduced_table.MergedTimeSeries{row_idx})
            % Concatenate cell arrays horizontally (e.g., 1×4 + 1×3 = 1×7)
            subject_series = reduced_table.MergedTimeSeries{row_idx};
            if iscell(subject_series)
                group_merged_series = [group_merged_series, subject_series];
            end
        end
        
        % Collect UniformChunkedData from this subject  
        if ~isempty(reduced_table.UniformChunkedData{row_idx})
            % Concatenate cell arrays horizontally (e.g., 1×4 + 1×3 = 1×7)
            subject_uniform = reduced_table.UniformChunkedData{row_idx};
            if iscell(subject_uniform)
                group_uniform_data = [group_uniform_data, subject_uniform];
            end
        end
    end
    
    MergedTimeSeries{group_idx} = group_merged_series;
    UniformChunkedData{group_idx} = group_uniform_data;
end

%% Create the final merged table
merged_table = table(UniversalSubject, FrequencyRange, Task, ChannelName, ...
                    MergedTimeSeries, UniformChunkedData);

fprintf('\nMerging completed!\n');
fprintf('Merged table size: %d rows, %d columns\n', height(merged_table), width(merged_table));

%% Save the merged table
save('merged_aligned_data.mat', 'merged_table', '-v7.3');
fprintf('Merged table saved to: merged_aligned_data.mat\n');

%% Display summary
fprintf('\nSummary:\n');
fprintf('Original unique subjects: %d\n', length(unique(reduced_table.SubjectName)));
fprintf('Unique combinations (FrequencyRange + Task + ChannelName): %d\n', n_groups);

% Display first few rows
fprintf('\nFirst few rows of merged table:\n');
disp(merged_table(1:min(5, height(merged_table)), 1:4));

% Display example data sizes
if height(merged_table) > 0 && ~isempty(merged_table.UniformChunkedData{1})
    fprintf('\nExample data sizes in first row:\n');
    uniform_data = merged_table.UniformChunkedData{1};
    if ~isempty(uniform_data) && ~isempty(uniform_data{1})
        fprintf('UniformChunkedData first element size: %d x %d\n', size(uniform_data{1}));
        fprintf('Number of trial groups: %d\n', length(uniform_data));
    end
end 