function NumberConfusion(cfg0,subject)

    %% Load MEG data
    disp('loading..')
    disp(subject)
    dot_data = load(fullfile(cfg0.root,'CleanData',subject,'dot_trials.mat'));
    dot_data = dot_data.dot_trials;
    dot_time = dot_data.time{1};
    disp('loaded data')
    
    arabic_data = load(fullfile(cfg0.root,'CleanData',subject,'arabic_trials.mat'));
    arabic_data = arabic_data.arabic_trials;  
    arabic_time = arabic_data.time{1};
    disp('loaded data')
    
    outputDir = fullfile(cfg0.root,cfg0.output_path,subject);
    if ~exist(outputDir,'dir'); mkdir(outputDir); end

    %{
    %% Try Separate Stim Types
    cfg =[];
    cfg.trials = num_data.trialinfo(:,13) == 2;
    num_data = ft_selectdata(cfg,num_data);
    num_labels = num_labels(num_data.trialinfo(:,13) == 2);
    %}

    %% Select Sample Dot Stims
    cfgS = [];
    cfgS.trials = dot_data.trialinfo(:,4) == 1;
    dot_data = ft_selectdata(cfgS,dot_data);

    %% Remove No Resp Trials
    cfgS = [];
    cfgS.trials = dot_data.trialinfo(:,8) ~= 0;
    dot_data = ft_selectdata(cfgS,dot_data);
    cfgS.trials = arabic_data.trialinfo(:,6) ~= 0;
    arabic_data = ft_selectdata(cfgS,arabic_data);

    %% Get Trial x Channels x Time Matrix
    cfgS = [];
    cfgS.keeptrials = true;
    cfgS.channel=cfg0.channel;
    %cfgS.latency = [-0.075 0.8];
    dot_data_TL = ft_timelockanalysis(cfgS,dot_data);
    arabic_data_TL = ft_timelockanalysis(cfgS,arabic_data);

    %% Decode
    cfg = [] ;
    cfg.method          = 'mvpa';
    cfg.latency         = cfg0.dot_timepoints;
    cfg.avgovertime     = 'yes';
    cfg.design          = dot_data_TL.trialinfo(:,5);
    %cfg.design = cfg.design(randperm(length(cfg.design)));
    cfg.features        = 'chan';
    cfg.mvpa            = [];
    cfg.mvpa.classifier = 'multiclass_lda';
    cfg.mvpa.metric     = 'conf';
    cfg.mvpa.k          = 5;
    cfg.mvpa.repeat = 1;
    cfg.mvpa.preproc    = {'undersample','average_samples'};
    conf_dots = ft_timelockstatistics(cfg, dot_data_TL);
    
    cfg.latency = cfg0.arabic_timepoints;
    cfg.design          = arabic_data_TL.trialinfo(:,4);
    conf_arabic = ft_timelockstatistics(cfg, arabic_data_TL);
    %% Save
    if ~exist(outputDir,'dir'); mkdir(outputDir); end 
    save(fullfile(outputDir,[cfg0.outputName,'_dots']),'conf_dots','-v7.3');
    save(fullfile(outputDir,[cfg0.outputName,'_arabic']),'conf_arabic','-v7.3');

    disp('saving....')

end