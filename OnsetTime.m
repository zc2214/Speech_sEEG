function Response_Homo1_onset = OnsetTime(EEG_Data, Trigger)
    Response_Homo1_onset = [];
    Response_Homo1_index = 1;
    for j = 1:length(EEG_Data.event)
        if strcmp(EEG_Data.event(j).type,Trigger)
            Response_Homo1_onset(Response_Homo1_index) = EEG_Data.event(j).latency;
            Response_Homo1_index = Response_Homo1_index + 1;
        end
    end
end