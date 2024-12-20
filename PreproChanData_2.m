function DataTable = PreproChanData(SubjectNameList) % Deleted DataMatFileName
    TaskNameSet = {'Exp1', 'Exp2', 'Exp3'};
    ConditionSet = {'Homo1', 'Homo2', 'Merged'};

    FrequencyRangeSet(1).LowerBound = 70;
    FrequencyRangeSet(1).UperBound = 140;
    FrequencyRangeSet(1).FrequencyRangeName = 'HGamma';

    FrequencyRangeSet(2).LowerBound = 30;
    FrequencyRangeSet(2).UperBound = 70;
    FrequencyRangeSet(2).FrequencyRangeName = 'Gamma';



    % Init Columns 
    %Order = {};
    Task = {};
    %Condition = {};
    SubjectName = {};
    ChannelName = {}; 
    FrequencyRange = {};

    Homo1_Signal = {};
    Homo2_Signal = {};
    Merged_Signal = {};

    Ans_Homo1_Signal = {};
    Ans_Homo2_Signal = {};
    Ans_Merged_Signal = {};
    
   
    Homo1_Noise = {};
    Homo2_Noise = {};
    Merged_Noise = {};
    
    Ans_Homo1_Noise = {};
    Ans_Homo2_Noise = {};
    Ans_Merged_Noise = {};
    
    

    Homo1_Timepoints = {};
    Homo2_Timepoints = {};
    Merged_Timepoints = {};
    Ans_Homo1_Timepoints = {};
    Ans_Homo2_Timepoints = {};
    Ans_Merged_Timepoints = {};



    for i = 1:length(SubjectNameList)
        tempSubjectName = SubjectNameList(i).Name;
        tempDataFolderDir = SubjectNameList(i).DataFolderDir;

            for TaskIndex = 2:2
                tempTaskName = TaskNameSet{TaskIndex};
                for FreIndex = 1:2
                    tempFrequencyRange = FrequencyRangeSet(FreIndex);
                    %EEG_Data = FittingData(tempDataFolderDir, tempSubjectName, tempTaskName, tempFrequencyRange, OrderIndex);
                    [posEEGData,negEEGData,Ans_posEEGData,Ans_negEEGData,MergedEEGData,Ans_MergedEEGData] = FittingData(tempDataFolderDir, tempSubjectName, tempTaskName, tempFrequencyRange);
                    SubChanList = EpochAndMean(posEEGData,negEEGData,Ans_posEEGData,Ans_negEEGData,MergedEEGData,Ans_MergedEEGData);
                    for ChanIndex = 1:length(SubChanList)
                        tempChan = SubChanList(ChanIndex);
                        % for ConditionIndex = 1:4

                            Task = [Task; tempTaskName];
                            SubjectName = [SubjectName; tempSubjectName];
                            ChannelName = [ChannelName; tempChan.Name];
                            FrequencyRange = [FrequencyRange; tempFrequencyRange];

                            Homo1_Noise = [Homo1_Noise; tempChan.Homo1_Noise];
                            Homo1_Signal = [Homo1_Signal; tempChan.Homo1_Signal];
                            
                            Homo2_Noise = [Homo2_Noise; tempChan.Homo2_Noise];
                            Homo2_Signal = [Homo2_Signal; tempChan.Homo2_Signal];
                            
                            Merged_Noise = [Merged_Noise; tempChan.Merged_Noise];
                            Merged_Signal = [Merged_Signal; tempChan.Merged_Signal];
                            
                            Ans_Homo1_Signal = [Ans_Homo1_Signal; tempChan.Ans_Homo1_Signal];
                            Ans_Homo2_Signal = [Ans_Homo2_Signal; tempChan.Ans_Homo2_Signal];
                            
                            Ans_Homo1_Noise = [Ans_Homo1_Noise; tempChan.Ans_Homo1_Noise];
                            Ans_Homo2_Noise = [Ans_Homo2_Noise; tempChan.Ans_Homo2_Noise];
                            
                            Ans_Merged_Noise = [Ans_Merged_Noise; tempChan.Ans_Merged_Noise];
                            Ans_Merged_Signal = [Ans_Merged_Signal; tempChan.Ans_Merged_Signal];
                            
                            Homo1_Timepoints = [Homo1_Timepoints; tempChan.Homo1_Timepoints];
                            Homo2_Timepoints = [Homo2_Timepoints; tempChan.Homo2_Timepoints];
                            Merged_Timepoints = [Merged_Timepoints; tempChan.Merged_Timepoints];
                            Ans_Homo1_Timepoints = [Ans_Homo1_Timepoints; tempChan.Ans_Homo1_Timepoints];
                            Ans_Homo2_Timepoints = [Ans_Homo2_Timepoints; tempChan.Ans_Homo2_Timepoints];
                            Ans_Merged_Timepoints = [Ans_Merged_Timepoints; tempChan.Ans_Merged_Timepoints];

                    end
                end
            end
        %end
    end

    DataTable = table(SubjectName, FrequencyRange, Task, ChannelName, Homo1_Signal, Homo1_Noise, Homo2_Signal, Homo2_Noise, Merged_Signal, Merged_Noise, Ans_Homo1_Signal, Ans_Homo1_Noise, Ans_Homo2_Signal,Ans_Homo2_Noise, Ans_Merged_Signal, Ans_Merged_Noise, Homo1_Timepoints, Homo2_Timepoints, Merged_Timepoints, Ans_Homo1_Timepoints, Ans_Homo2_Timepoints, Ans_Merged_Timepoints);


end




function [posEEGData,negEEGData,Ans_posEEGData,Ans_negEEGData,MergedEEGData,Ans_MergedEEGData] = FittingData(DataFolderDir, SubjectName, TaskName, FrequencyRange) 
    filename_Homo1 = [DataFolderDir, '/', SubjectName, ['/', TaskName,'/', 'posEEG1_',num2str(TaskName),'.set']];             
    posEEG1 = pop_loadset(filename_Homo1); 
    [posEEG3, com, b] = pop_eegfiltnew( posEEG1, FrequencyRange.LowerBound, FrequencyRange.UperBound);
    if  ~strcmp(FrequencyRange.FrequencyRangeName, 'ERP')     
        for i=1:size(posEEG3.data,1)
            posEEG3.data(i,:)=abs(hilbert(posEEG3.data(i,:)));
        end
        fprintf('Hilbert Done!\n');

    else

        fprintf('ERP Just Raw!\n')
    end
    posEEGData = posEEG3;
    

    filename_Homo2 = [DataFolderDir, '/', SubjectName, ['/', TaskName,'/', 'negEEG1_',num2str(TaskName),'.set']];              
    negEEG1 = pop_loadset(filename_Homo2); %the 1st sound 
    [negEEG3, com, b] = pop_eegfiltnew( negEEG1, FrequencyRange.LowerBound, FrequencyRange.UperBound);
    if  ~strcmp(FrequencyRange.FrequencyRangeName, 'ERP')     
        for i=1:size(negEEG3.data,1)
            negEEG3.data(i,:)=abs(hilbert(negEEG3.data(i,:)));
        end
        fprintf('Hilbert Done!\n');

    else

        fprintf('ERP Just Raw!\n')
    end
    negEEGData = negEEG3;
    
    
     
    filename_Merged = [DataFolderDir, '/', SubjectName, ['/', TaskName,'/', 'MergedEEG1_',num2str(TaskName),'.set']];             
    MergedEEG1 = pop_loadset(filename_Merged); 
    [MergedEEG3, com, b] = pop_eegfiltnew( MergedEEG1, FrequencyRange.LowerBound, FrequencyRange.UperBound);
    if  ~strcmp(FrequencyRange.FrequencyRangeName, 'ERP')     
        for i=1:size(MergedEEG3.data,1)
            MergedEEG3.data(i,:)=abs(hilbert(MergedEEG3.data(i,:)));
        end
        fprintf('Hilbert Done!\n');

    else

        fprintf('ERP Just Raw!\n')
    end
    MergedEEGData = MergedEEG3;
    
    
    filename_Ans_Homo1 = [DataFolderDir, '/', SubjectName, ['/', TaskName,'/', 'Ans_posEEG1_',num2str(TaskName),'.set']];             
    pos08EEG1 = pop_loadset(filename_Ans_Homo1); %the 1st sound 
    [pos08EEG3, com, b] = pop_eegfiltnew( pos08EEG1, FrequencyRange.LowerBound, FrequencyRange.UperBound);
    if  ~strcmp(FrequencyRange.FrequencyRangeName, 'ERP')     
        for i=1:size(pos08EEG3.data,1)
            pos08EEG3.data(i,:)=abs(hilbert(pos08EEG3.data(i,:)));
        end
        fprintf('Hilbert Done!\n');

    else

        fprintf('ERP Just Raw!\n')
    end
    Ans_posEEGData = pos08EEG3;
    
    
    
   filename_Ans_Homo2 = [DataFolderDir, '/', SubjectName, ['/', TaskName,'/', 'Ans_negEEG1_',num2str(TaskName),'.set']];             
    neg08EEG1 = pop_loadset(filename_Ans_Homo2); %the 1st sound 
    [neg08EEG3, com, b] = pop_eegfiltnew( neg08EEG1, FrequencyRange.LowerBound, FrequencyRange.UperBound);
    if  ~strcmp(FrequencyRange.FrequencyRangeName, 'ERP')     
        for i=1:size(neg08EEG3.data,1)
            neg08EEG3.data(i,:)=abs(hilbert(neg08EEG3.data(i,:)));
        end
        fprintf('Hilbert Done!\n');

    else

        fprintf('ERP Just Raw!\n')
    end
    Ans_negEEGData = neg08EEG3;
    
    
    filename_Ans_Merged = [DataFolderDir, '/', SubjectName, ['/', TaskName,'/', 'Ans_MergedEEG1_',num2str(TaskName),'.set']];             
    Ans_MergedEEG1 = pop_loadset(filename_Ans_Merged); 
    [Ans_MergedEEG3, com, b] = pop_eegfiltnew( Ans_MergedEEG1, FrequencyRange.LowerBound, FrequencyRange.UperBound);
    if  ~strcmp(FrequencyRange.FrequencyRangeName, 'ERP')     
        for i=1:size(Ans_MergedEEG3.data,1)
            Ans_MergedEEG3.data(i,:)=abs(hilbert(Ans_MergedEEG3.data(i,:)));
        end
        fprintf('Hilbert Done!\n');

    else

        fprintf('ERP Just Raw!\n')
    end
    Ans_MergedEEGData = Ans_MergedEEG3;
    
    
end






function SubChanList = EpochAndMean(posEEGData,negEEGData,Ans_posEEGData,Ans_negEEGData,MergedEEGData,Ans_MergedEEGData)

    

    %% Epoching 
    [Homo1, indices] = pop_epoch(posEEGData, {'1'}, [-0.1 1.5]);
    [Homo2, indices] = pop_epoch(negEEGData, {'2'}, [-0.1 1.5]);
    [Merged, indices] = pop_epoch(MergedEEGData, {'3'}, [-0.1 1.5]);
    
    [Ans_Homo1, indices] = pop_epoch(Ans_posEEGData, {'1'}, [-0.1 1.5]);
    [Ans_Homo2, indices] = pop_epoch(Ans_negEEGData, {'2'}, [-0.1 1.5]);
    [Ans_Merged, indices] = pop_epoch(Ans_MergedEEGData, {'3'}, [-0.1 1.5]);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% AS Structure Discription %%
    % srate - sampling rate; chanlocs.labels - Chhannel Lables
    % data - Channel x Timepoints x Trails 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Baseline Correction
    Homo1 = pop_rmbase( Homo1, [-99 0]);
    Homo2 = pop_rmbase( Homo2, [-99 0]);
    Merged = pop_rmbase( Merged, [-99 0]);
    
    Ans_Homo1 = pop_rmbase( Ans_Homo1, [-99 0]);
    Ans_Homo2 = pop_rmbase( Ans_Homo2, [-99 0]);
    Ans_Merged = pop_rmbase( Ans_Merged, [-99 0]);

    %% Packing The Data
    
    for i = 1:Homo1.nbchan
        Chan.Homo1_Raw = squeeze(permute(Homo1.data(i,:,:), [1,2,3])); % Wait to be test
        Chan.Homo2_Raw = squeeze(permute(Homo2.data(i,:,:), [1,2,3]));
        Chan.Merged_Raw = squeeze(permute(Merged.data(i,:,:), [1,2,3]));
        
        Chan.Name = Homo1.chanlocs(i).labels;
        Chan.Index = i; % Convinient to show the Channel Processing rate
        Chan.Homo1_Timepoints = Homo1.times;
        Chan.Homo2_Timepoints = Homo2.times;
        Chan.Merged_Timepoints = Merged.times;
        
        NoiseIndex = floor((-Chan.Homo1_Timepoints(1))/(Chan.Homo1_Timepoints(2)-Chan.Homo1_Timepoints(1))); %%To Be Checked
        Chan.Homo1_Noise = Chan.Homo1_Raw(1: NoiseIndex, :);
        Chan.Homo1_Signal = Chan.Homo1_Raw(NoiseIndex+1 : end, :);
        Chan.Homo2_Noise = Chan.Homo2_Raw(1: NoiseIndex, :);
        Chan.Homo2_Signal = Chan.Homo2_Raw(NoiseIndex+1 : end, :);
        Chan.Merged_Noise = Chan.Merged_Raw(1: NoiseIndex, :);
        Chan.Merged_Signal = Chan.Merged_Raw(NoiseIndex+1 : end, :);
        
        Chan.Ans_Homo1_Raw = squeeze(permute(Ans_Homo1.data(i,:,:), [1,2,3])); % Wait to be test
        Chan.Ans_Homo2_Raw = squeeze(permute(Ans_Homo2.data(i,:,:), [1,2,3]));
        Chan.Ans_Merged_Raw = squeeze(permute(Ans_Merged.data(i,:,:), [1,2,3]));
        
        Chan.Ans_Homo1_Timepoints = Ans_Homo1.times;
        Chan.Ans_Homo2_Timepoints = Ans_Homo2.times;
        Chan.Ans_Merged_Timepoints = Ans_Merged.times;
        
        Chan.Ans_Homo1_Signal = Chan.Ans_Homo1_Raw(NoiseIndex+1 : end, :); 
        Chan.Ans_Homo1_Noise = Chan.Ans_Homo1_Raw(1: NoiseIndex, :);
        Chan.Ans_Homo2_Signal = Chan.Ans_Homo2_Raw(NoiseIndex+1 : end, :);
        Chan.Ans_Homo2_Noise = Chan.Ans_Homo2_Raw(1: NoiseIndex, :);
        Chan.Ans_Merged_Noise = Chan.Ans_Merged_Raw(1: NoiseIndex, :);
        Chan.Ans_Merged_Signal = Chan.Ans_Merged_Raw(NoiseIndex+1 : end, :);

        SubChanList(i) = Chan;
    end

end

