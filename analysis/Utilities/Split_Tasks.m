function Split_Tasks(cfg0,subject)
    

    datadir = cfg0.datadir;
    load(fullfile(datadir,'CleanData',subject,'data2.mat'));  
    
    %% Create Fields for Class Labels
    det_labels = zeros(size(find(data.trialinfo(:,3)==2),1),1);
    abs_high_idx = data.trialinfo(:,7) == 2 & data.trialinfo(:,10) == 2;
    abs_low_idx =  data.trialinfo(:,7) == 2 & data.trialinfo(:,10) == 1;
    pres_high_idx =  data.trialinfo(:,7) == 1 & data.trialinfo(:,10) == 2;
    pres_low_idx = data.trialinfo(:,7) == 1 & data.trialinfo(:,10) == 1;
    det_labels(abs_high_idx) = 1;
    det_labels(abs_low_idx) = 2;
    det_labels(pres_low_idx) = 3;
    det_labels(pres_high_idx) = 4;
    data.no_det_resp =  data.trialinfo(:,7) == 0 | data.trialinfo(:,10) == 0;
    
    %number labels
    num_labels = data.trialinfo(~isnan(data.trialinfo(:,14)) & data.trialinfo(:,3) == 1,14);

    %% Save By Task

    %detection task
    root = 'D:\bbarnett\Documents\Zero\data\CleanData';
    cfg.channel = 'MEG';
    cfg.trials = data.trialinfo(:,3) == 2; %select detection task
    det_data = ft_selectdata(cfg,data);
    det_data.det_labels = det_labels(det_labels>0);
    save(fullfile(root,subject,'det_data2.mat'),'det_data');
    
    %numerical task
    cfg = [];
    root = 'D:\bbarnett\Documents\Zero\data\CleanData';
    cfg.channel = 'MEG';
    cfg.trials = data.trialinfo(:,3) == 1;
    num_data = ft_selectdata(cfg,data);
    num_data.num_labels = num_labels+1;
    save(fullfile(root,subject,'num_data2.mat'),'num_data');




    clear data num_data det_data 


end