function  RSA_DetControl(cfg0,subject)
    
    %Function to extract betas vectors needed to form neural RDM.
    %Produces a beta vector of Nsensor length for each condition at each time
    %point. Test the control analysis for Detection task, replicating
    %phenomenal magnitude work.

    %% Load MEG Data
    disp('loading..')
    disp(subject)
    data = load(fullfile(cfg0.root,'CleanData',subject,'det_data.mat'));
    data = data.det_data;  
    
    %% Create Design Matrix of Dummy Coded Predictors
    trial_info = data.trialinfo;
    des_mat = zeros(length(trial_info),cfg0.num_predictors);

    % Get Indexes of Different Classes of Interest
    % Indexes = [Miniblock,Detection Decision, Confidence]
    house_abs_high_idx = trial_info(:,4) == 1 & trial_info(:,7) == 2 & trial_info(:,10) == 2;
    house_abs_low_idx = trial_info(:,4) == 1 & trial_info(:,7) == 2 & trial_info(:,10) == 1;
    house_pres_high_idx = trial_info(:,4) == 1 & trial_info(:,7) == 1 & trial_info(:,10) == 2;
    house_pres_low_idx = trial_info(:,4) == 1 & trial_info(:,7) == 1 & trial_info(:,10) == 1;
    
    face_abs_high_idx = trial_info(:,4) == 2 & trial_info(:,7) == 2 & trial_info(:,10) == 2;
    face_abs_low_idx = trial_info(:,4) == 2 & trial_info(:,7) == 2 & trial_info(:,10) == 1;
    face_pres_high_idx = trial_info(:,4) == 2 & trial_info(:,7) == 1 & trial_info(:,10) == 2;
    face_pres_low_idx = trial_info(:,4) == 2 & trial_info(:,7) == 1 & trial_info(:,10) == 1;

    % Fill Design Matrix
    des_mat(house_abs_high_idx,1)            = 1;
    des_mat(house_abs_low_idx,2)             = 1;
    des_mat(house_pres_low_idx,3)            = 1;
    des_mat(house_pres_high_idx,4)           = 1;
    des_mat(face_abs_high_idx,5)             = 1;
    des_mat(face_abs_low_idx,6)              = 1;
    des_mat(face_pres_low_idx,7)             = 1;
    des_mat(face_pres_high_idx,8)            = 1;

    %Remove Rows With No Condition (e.g. if they made no response on a trial)
    row_all_zeros = all(des_mat == 0,2);
    des_mat(row_all_zeros,:) = [];

    %Remove These Trials From Data Too
    trls = ~(row_all_zeros); 
    cfgS = [];
    cfgS.trials =trls;
    data = ft_selectdata(cfgS,data);

    %% Get Trial x Channels x Time matrix
    cfgT = [];
    cfgT.keeptrials = 'yes';
    cfgT.channel = cfg0.channels;
    tl_data = ft_timelockanalysis(cfgT, data);

    %% Run RSA
    rhos = RunRSA(cfg0,tl_data,des_mat);
    
    %% Save
    outputDir = fullfile(cfg0.root,cfg0.output_path,subject,cfg0.mRDM_file);
    disp(outputDir)
    if ~exist(outputDir,'dir'); mkdir(outputDir); end 
    save(fullfile(outputDir,'rhos_no_diag.mat'), 'rhos')

    
end
