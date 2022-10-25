function NumberConfusion(cfg0,subject)

    %% Load MEG data
    disp('loading..')
    disp(subject)
    num_data = load(fullfile(cfg0.root,'CleanData',subject,'num_data.mat'));
    num_data = num_data.num_data;  
    time = num_data.time{1};
    disp('loaded data')
    
    outputDir = fullfile(cfg0.root,cfg0.output_path,subject);
    if ~exist(outputDir,'dir'); mkdir(outputDir); end

    %% Store class labels
    num_labels = num_data.num_labels;

    %{
    %% Try Separate Stim Types
    cfg =[];
    cfg.trials = num_data.trialinfo(:,13) == 2;
    num_data = ft_selectdata(cfg,num_data);
    num_labels = num_labels(num_data.trialinfo(:,13) == 2);
    %}
    
    %% Get Trial x Channels x Time Matrix
    cfgS = [];
    cfgS.keeptrials = true;
    cfgS.channel=cfg0.channel;
    num_data = ft_timelockanalysis(cfgS,num_data);
    

    %% Decode
    cfg = [] ;
    cfg.method          = 'mvpa';
    cfg.latency         = cfg0.timepoints;
    cfg.avgovertime     = 'yes';
    cfg.design          = num_labels;
    cfg.features        = 'chan';
    cfg.mvpa            = [];
    cfg.mvpa.classifier = 'multiclass_lda';
    cfg.mvpa.metric     = 'conf';
    cfg.mvpa.k          = 5;
    conf = ft_timelockstatistics(cfg, num_data);

    %% Save
    if ~exist(outputDir,'dir'); mkdir(outputDir); end 
    save(fullfile(outputDir,cfg0.outputName),'conf','-v7.3');
    disp('saving....')

end