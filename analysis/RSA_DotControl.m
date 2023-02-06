function  RSA_DotControl(cfg0,subject)
    
    %Function to extract betas vectors needed to form neural RDM.
    %Produces a beta vector of Nsensor length for each condition at each time
    %point. Test the control analysis for Dot Task.

    %% Load MEG Data
    disp('loading..')
    disp(subject)
    data = load(fullfile(cfg0.root,'CleanData',subject,'dot_trials.mat'));
    data = data.dot_trials;  
    
    %% Select Sample Dot Stims
    cfgS = [];
    cfgS.trials = data.trialinfo(:,4) == 1;
    data = ft_selectdata(cfgS,data);

    %% Create Design Matrix of Dummy Coded Predictors
    trial_info = data.trialinfo;
    des_mat = zeros(length(trial_info),cfg0.num_predictors*2);

    % Get Indexes of Different Classes of Interest
    % Indexes = [Task, Number,StimSet]
   stnd_zero_idx = trial_info(:,3) == 1 & trial_info(:,5) == 0 & trial_info(:,6) == 1;
   stnd_one_idx = trial_info(:,3) == 1 & trial_info(:,5) == 1 & trial_info(:,6) == 1;
   stnd_two_idx = trial_info(:,3) == 1 & trial_info(:,5) == 2 & trial_info(:,6) == 1;
   stnd_three_idx = trial_info(:,3) == 1 & trial_info(:,5) == 3 & trial_info(:,6) == 1;
   stnd_four_idx = trial_info(:,3) == 1 & trial_info(:,5) == 4 & trial_info(:,6) == 1;
   stnd_five_idx = trial_info(:,3) == 1 & trial_info(:,5) == 5 & trial_info(:,6) == 1;

   ctrl_zero_idx = trial_info(:,3) == 1 & trial_info(:,5) == 0 & trial_info(:,6) == 2;
   ctrl_one_idx = trial_info(:,3) == 1 & trial_info(:,5) == 1 & trial_info(:,6) == 2;
   ctrl_two_idx = trial_info(:,3) == 1 & trial_info(:,5) == 2 & trial_info(:,6) == 2;
   ctrl_three_idx = trial_info(:,3) == 1 & trial_info(:,5) == 3 & trial_info(:,6) == 2;
   ctrl_four_idx = trial_info(:,3) == 1 & trial_info(:,5) == 4 & trial_info(:,6) == 2;
   ctrl_five_idx = trial_info(:,3) == 1 & trial_info(:,5) == 5 & trial_info(:,6) == 2;

    % Fill Design Matrix
    des_mat(stnd_zero_idx, 1)           = 1;
    des_mat(stnd_one_idx, 2)            = 1;
    des_mat(stnd_two_idx, 3)            = 1;
    des_mat(stnd_three_idx, 4)          = 1;
    des_mat(stnd_four_idx, 5)          = 1;
    des_mat(stnd_five_idx, 6)          = 1;

    des_mat(ctrl_zero_idx, 7)           = 1;
    des_mat(ctrl_one_idx, 8)            = 1;
    des_mat(ctrl_two_idx, 9)            = 1;
    des_mat(ctrl_three_idx, 10)          = 1;
    des_mat(ctrl_four_idx, 11)          = 1;
    des_mat(ctrl_five_idx, 12)          = 1;

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
