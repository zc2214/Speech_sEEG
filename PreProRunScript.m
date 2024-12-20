% This Script is for whole process of the subject
% This Script has no Activated Test, cluster test, SubPicDir, just do preprossing, so Called 3_2_1, _1 means the 1st step

% This Scrit will be the stable used version in future, bucause it only do basic prepration
% This Script use the PathSetting to set Path
clear all;
warning off;
diary 'Script.log'
diary on;

PathStruct = PathSetting();

SubjectNameList = GetSubjectNameList(PathStruct.RawData);

for i = [5,6,7,8,9,10,12,14]
    % Show Date and time
    datetime
    fprintf('\n\n\n')
    
    % Preprossing
    tempSubjectName = SubjectNameList(i); 
    DataTable = PreproChanData_2(tempSubjectName); 
    
    % Save Data
    MatDir = PathStruct.DataMat;
    
    if exist(MatDir,'dir')
        % rmdir(PicFolderName,'s')
    else
        mkdir(MatDir);
        fprintf('Folder Newed!!!\n');
    end
    DataTableMatFile = [MatDir, '/', tempSubjectName.Name, '.mat'];
    save(DataTableMatFile, 'tempSubjectName', 'DataTable', '-v7.3');
    fprintf('%d of %d subject done!\n\n\n', i, length(SubjectNameList));
    
end

diary off;