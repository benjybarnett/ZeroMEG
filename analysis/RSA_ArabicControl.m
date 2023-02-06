function  RSA_ArabicControl(cfg0,subject)
    
    %Function to extract betas vectors needed to form neural RDM.
    %Produces a beta vector of Nsensor length for each condition at each time
    %point. Test the control analysis for Arabic Task.

    %% Load MEG Data
    disp('loading..')
    disp(subject)
    data = load(fullfile(cfg0.root,'CleanData',subject,'arabic_trials.mat'));
    data = data.arabic_trials;  
    

    %% Create Design Matrix of Dummy Coded Porangeictors
    trial_info = data.trialinfo;
    des_mat = zeros(length(trial_info),cfg0.num_predictors*2);

    % Get Indexes of Different Classes of Interest
    % Indexes = [Task, Number,StimSet]
   orange_zero_idx =  trial_info(:,4) == 0 & trial_info(:,5) == 2;
   orange_one_idx =  trial_info(:,4) == 1 & trial_info(:,5) == 2;
   orange_two_idx =  trial_info(:,4) == 2 & trial_info(:,5) == 2;
   orange_three_idx =  trial_info(:,4) == 3 & trial_info(:,5) == 2;
   orange_four_idx =  trial_info(:,4) == 4 & trial_info(:,5) == 2;
   orange_five_idx =  trial_info(:,4) == 5 & trial_info(:,5) == 2;

   blue_zero_idx =  trial_info(:,4) == 0 & trial_info(:,5) == 1;
   blue_one_idx =  trial_info(:,4) == 1 & trial_info(:,5) == 1;
   blue_two_idx =  trial_info(:,4) == 2 & trial_info(:,5) == 1;
   blue_three_idx =  trial_info(:,4) == 3 & trial_info(:,5) == 1;
   blue_four_idx =  trial_info(:,4) == 4 & trial_info(:,5) == 1;
   blue_five_idx =  trial_info(:,4) == 5 & trial_info(:,5) == 1;

    % Fill Design Matrix
    des_mat(orange_zero_idx, 1)           = 1;
    des_mat(orange_one_idx, 2)            = 1;
    des_mat(orange_two_idx, 3)            = 1;
    des_mat(orange_three_idx, 4)          = 1;
    des_mat(orange_four_idx, 5)          = 1;
    des_mat(orange_five_idx, 6)          = 1;

    des_mat(blue_zero_idx, 7)           = 1;
    des_mat(blue_one_idx, 8)            = 1;
    des_mat(blue_two_idx, 9)            = 1;
    des_mat(blue_three_idx, 10)          = 1;
    des_mat(blue_four_idx, 11)          = 1;
    des_mat(blue_five_idx, 12)          = 1;

    %% Get Trial x Channels x Time matrix
    cfgT = [];
    cfgT.keeptrials = 'yes';
    cfgT.channel = cfg0.channels;
    tl_data = ft_timelockanalysis(cfgT, data);

    %% Run RSA
    rhos = RunCrossRSA(cfg0,tl_data,des_mat);

    %% Save
    outputDir = fullfile(cfg0.root,cfg0.output_path,subject,cfg0.mRDM_file);
    disp(outputDir)
    if ~exist(outputDir,'dir'); mkdir(outputDir); end 
    save(fullfile(outputDir,'rhos_no_diag.mat'), 'rhos')

    
end
