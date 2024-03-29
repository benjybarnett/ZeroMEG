function  RSA_Cross(cfg0,subject)
    
    %Function to extract betas vectors needed to form neural RDM.
    %Produces a beta vector of Nsensor length for each condition at each time
    %point. Used to test cross-decoding of arabic and numerals.

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
    cfgS.latency = [-0.1 0.8]; %set to same as arabic trials
    dot_data = ft_selectdata(cfgS,dot_data);
    
    %% Remove No Resp Trials
    cfgS = [];
    cfgS.trials = dot_data.trialinfo(:,8) ~= 0;
    dot_data = ft_selectdata(cfgS,dot_data);
    cfgS.trials = arabic_data.trialinfo(:,6) ~= 0;
    arabic_data = ft_selectdata(cfgS,arabic_data);

    %% Append numerals and dot datasets
    %edit trialinfo to just stim columns to help append
    arabic_data.trialinfo = arabic_data.trialinfo(:,[3,4]);
    dot_data.trialinfo = dot_data.trialinfo(:,[3,5]);
    data = ft_appenddata([],dot_data,arabic_data);


    %% Create Design Matrix of Dummy Coded Predictors
    trial_info = data.trialinfo;
    des_mat = zeros(length(trial_info),cfg0.num_predictors);

    % Get Indexes of Different Classes of Interest
    labels = trial_info(:,2); task = trial_info(:,1);
    
    %dots
    dots_zero_idx = labels == 0 & task == 1;
    dots_one_idx = labels == 1 & task == 1;
    dots_two_idx = labels == 2 & task == 1;
    dots_three_idx = labels == 3 & task == 1;
    dots_four_idx = labels == 4 & task == 1;
    dots_five_idx = labels == 5 & task == 1;

    %arabic
    arabic_zero_idx = labels == 0 & task == 2;
    arabic_one_idx = labels == 1 & task == 2;
    arabic_two_idx = labels == 2 & task == 2;
    arabic_three_idx = labels == 3 & task == 2;
    arabic_four_idx = labels == 4 & task == 2;
    arabic_five_idx = labels == 5 & task == 2;

    % Fill Design Matrix
    des_mat(arabic_zero_idx,1)                 = 1;
    des_mat(arabic_one_idx,2)                  = 1;
    des_mat(arabic_two_idx,3)                  = 1;
    des_mat(arabic_three_idx,4)                = 1;
    des_mat(arabic_four_idx,5)                 = 1;
    des_mat(arabic_five_idx,6)                 = 1;

    des_mat(dots_zero_idx,7)                 = 1;
    des_mat(dots_one_idx,8)                  = 1;
    des_mat(dots_two_idx,9)                  = 1;
    des_mat(dots_three_idx,10)                = 1;
    des_mat(dots_four_idx,11)                 = 1;
    des_mat(dots_five_idx,12)                 = 1;


    %% Get Trial x Channels x Time matrix
    cfgT = [];
    cfgT.keeptrials = 'yes';
    cfgT.channel = cfg0.channels;
    tl_data= ft_timelockanalysis(cfgT, data);

    %% Run RSA
    rhos = RunCrossRSA(cfg0,tl_data,des_mat);

    
    %% Save
    if ~cfg0.removeDiag
        outputDir = fullfile(cfg0.root,cfg0.output_path,subject,cfg0.mRDM_file);
    elseif cfg0.removeDiag
        outputDir = fullfile(cfg0.root,cfg0.output_path,subject,cfg0.mRDM_file,'NoDiag');
    end
    if ~exist(outputDir,'dir'); mkdir(outputDir); end
    save(fullfile(outputDir,'rhos_no_diag.mat'), 'rhos')


    if cfg0.plot
        figure; plot(dot_time,dot_rhos);hold on;plot(arabic_time,arabic_rhos);xline(0);yline(0);
        legend('Dots','Numerals')
    end
end
