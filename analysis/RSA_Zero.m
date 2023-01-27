function  RSA_Zero(cfg0,subject)
    
    %Function to extract betas vectors needed to form neural RDM.
    %Produces a beta vector of Nsensor length for each condition at each time
    %point. Used to test the representational structure of zero wrt to other numbers.

    %% Load MEG Number Data
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


    %% Create Design Matrix of Dummy Coded Predictors
    % Dots
    trial_info = dot_data.trialinfo;
    dots_des_mat = zeros(length(trial_info),cfg0.num_predictors);

    % Get Indexes of Different Classes of Interest
    labels = dot_data.trialinfo(:,5);
    zero_idx = labels == 0;
    one_idx = labels == 1;
    two_idx = labels == 2;
    three_idx = labels == 3;
    four_idx = labels == 4;
    five_idx = labels == 5;

    % Fill Design Matrix
    dots_des_mat(zero_idx,1)                 = 1;
    dots_des_mat(one_idx,2)                  = 1;
    dots_des_mat(two_idx,3)                  = 1;
    dots_des_mat(three_idx,4)                = 1;
    dots_des_mat(four_idx,5)                 = 1;
    dots_des_mat(five_idx,6)                 = 1;

    % Arabic
    trial_info = arabic_data.trialinfo;
    arabic_des_mat = zeros(length(trial_info),cfg0.num_predictors);

    % Get Indexes of Different Classes of Interest
    labels = arabic_data.trialinfo(:,4);
    zero_idx = labels == 0;
    one_idx = labels == 1;
    two_idx = labels == 2;
    three_idx = labels == 3;
    four_idx = labels == 4;
    five_idx = labels == 5;

    % Fill Design Matrix
    arabic_des_mat(zero_idx,1)                 = 1;
    arabic_des_mat(one_idx,2)                  = 1;
    arabic_des_mat(two_idx,3)                  = 1;
    arabic_des_mat(three_idx,4)                = 1;
    arabic_des_mat(four_idx,5)                 = 1;
    arabic_des_mat(five_idx,6)                 = 1;


    %% Get Trial x Channels x Time matrix
    cfgT = [];
    cfgT.keeptrials = 'yes';
    cfgT.channel = cfg0.channels;
    tl_data_dot = ft_timelockanalysis(cfgT, dot_data);
    tl_data_arabic = ft_timelockanalysis(cfgT,arabic_data);

    %% Run RSA
    dot_rhos = RunRSA(cfg0,tl_data_dot,dots_des_mat);
    arabic_rhos = RunRSA(cfg0,tl_data_arabic,arabic_des_mat);

    
    %% Save
    dotOutputDir = fullfile(cfg0.root,cfg0.output_path,subject,cfg0.dot_output_folder);
    arabicOutputDir = fullfile(cfg0.root,cfg0.output_path,subject,cfg0.arabic_output_folder);
    if ~exist(dotOutputDir,'dir'); mkdir(dotOutputDir); end 
    if ~exist(arabicOutputDir,'dir'); mkdir(arabicOutputDir); end
    save(fullfile(dotOutputDir,'rhos_no_diag.mat'), 'dot_rhos')
    save(fullfile(arabicOutputDir,'rhos_no_diag.mat'), 'arabic_rhos')


    if cfg0.plot
        figure; plot(dot_time,dot_rhos);hold on;plot(arabic_time,arabic_rhos);xline(0);yline(0);
        legend('Dots','Numerals')
    end
end
