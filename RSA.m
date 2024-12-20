% should inculde Rob Campbell - November 2009 shadedErrorBar.m for plot

% Load required data
load P2_Test_AT_Select_Clean.mat

% Parameters
time_win = 25; % the RSA will be averaged by the time_win
time_step = 1; % r will be computed based on the time_step * channel 
num_con = 50; % 50 stimuli in-tol
time_data_noise = 51;
time_data_singal = 512;
time_tol = time_data_noise + time_data_singal;
ts = int16((time_tol-time_win)/time_step)-1;
num_area = 36;
roi_ls = [19:29]; 
data_table = RegionDataTable_Merged;

% Initialize variables
seeg_rdm_array = cell(num_area,1);
cor_array = cell(num_area,1);
permu_array_clusters = cell(num_area,1);
permu_array_p = cell(num_area,1);
permu_array_t = cell(num_area,1);
permu_array_distribution = cell(num_area,1);
color_ls = {[1 0 0],[1 97/255 0],[1 1 0],[0 1 0],[64/255 224/255 208/255],[0 0 1],[87/255 6/255 140/255]};
with_cluster_area_ls = {};

% SEEG RDM calculation
for n = roi_ls
    disp(n);
    data_noise = [data_table{n,5}{:}];
    data_signal = [data_table{n,6}{:}];
    num_channel = size(data_table{n,6}{:},2); 
    eeg_data = zeros(num_channel, time_tol, num_con);
    
    % Prepare EEG data
    for i = 1:num_channel
        for j = 1:time_data_noise
            temp_eeg = data_noise{i};
            eeg_data(i,j,:) = temp_eeg(j,:);
        end
        for j = time_data_noise+1:time_tol
            temp_eeg = data_signal{i};
            eeg_data(i,j,:) = temp_eeg(j-time_data_noise,:);
        end
    end

    % Reshape data for correlation
    data = zeros(num_channel, ts, num_con, time_win);
    for j = 1:num_channel
        for k = 1:ts
            for i = 1:num_con
                for m = 1:time_win
                    data(j,k,i,m) = eeg_data(j,k*time_step+m,i);
                end
            end
        end
    end

    % Compute RDM
    rdm = zeros(num_channel, ts, num_con, num_con);
    for m = 1:num_channel
        for i = 1:ts
            for j = 1:num_con
                for k = 1:num_con
                    r = corrcoef(data(m,i,j,:),data(m,i,k,:));
                    rdm(m,i,j,k) = 1 - abs(r(1,2));
                end
            end
        end
    end
    seeg_rdm_array{n} = rdm;
end
save("seeg_rdm_NewOnset_rdm.mat", "seeg_rdm_array", '-v7.3');

% RDM Correlation Calculation
for n = roi_ls
    num_chan = size(seeg_rdm_array{n});
    num_chan = num_chan(1);
    cor_subarray = zeros(num_chan, ts);
    for chan = 1:num_chan 
        for t = 1:ts
            disp([n chan t]);
            seeg_rdm = zeros(50, 50);
            temp_array = seeg_rdm_array{n};
            seeg_rdm(:,:) = temp_array(chan,t,:,:);
            cor_Pearson = corr(rdm,seeg_rdm,'Type','Pearson');
            cor_subarray(chan,t) = cor_Pearson(1,2);
        end
    end
    cor_array{n} = cor_subarray;
end
save("cor.mat", "cor_array", '-v7.3');

% Permutation Testing
for k = roi_ls
    temp_cor_array = cor_array{k};
    num_chan = size(temp_cor_array, 1);
    [clusters, p_values, t_sums, permutation_distribution]  = ...
        permutest(permute(temp_cor_array, [2, 1]), zeros(ts, num_chan));
    permu_array_clusters{k} = clusters;
    permu_array_p{k} = p_values;
    permu_array_t{k} = t_sums;
    permu_array_distribution{k} = permutation_distribution;
end
save("permutest.mat", "permu_array_clusters", "permu_array_p", ...
    "permu_array_t", "permu_array_distribution", '-v7.3');

% Visualization and Clustering
for roi = roi_ls
    time_points = [data_table{roi,7}{:}];
    time_points = time_points(:,1:ts);
    cor_subarray = cor_array{roi};
    permu_p_temparray = permu_array_p{roi};
    permu_clusters_temparray = permu_array_clusters{roi};
    permu_clusters_subarray = {};
    name = data_table{roi,4}{:};
    type = data_table{roi,2}{:};

    for i = 1:length(permu_p_temparray)
        p = permu_p_temparray(i);
        if p < 0.05
            permu_clusters_subarray{end+1} = permu_clusters_temparray(i);
        end
    end
    
    hold on
    for j = 1:length(permu_clusters_subarray)
        color = color_ls{min(j, 7)};
        cluster = [permu_clusters_subarray{j}{:}];
        xline(time_points(cluster(1)), "Color", color);
        xline(time_points(cluster(end)), "Color", color);
    end

    if ~isempty(permu_clusters_subarray)
        with_cluster_area_ls{end+1} = name+"_"+type+"_cor";
    end

    if size(cor_subarray, 1) == 1
        title(name+"-"+type+"-cor");
        plot(time_points, cor_subarray);
    else
        title(name+"-"+type+"-cor");
        shadedErrorBar(time_points, cor_subarray', {@median, @std});
    end
    hold off
    print(name+"_"+type+"_cor", "-dtiff", "-r200");
    clf
end
