function  RSA_Zero(cfg0,subject)
    
    %Function to extract betas vectors needed to form neural RDM.
    %Produces a beta vector of Nsensor length for each condition at each time
    %point. Used to test the representational structure of zero wrt to other numbers.

    %% Load MEG Number Data
    disp('loading..')
    disp(subject)
    data = load(fullfile(cfg0.root,'CleanData',subject,'num_data.mat'));
    data = data.num_data;  
   
    %% Create Design Matrix of Dummy Coded Predictors
    trial_info = data.trialinfo;
    des_mat = zeros(length(trial_info),cfg0.num_predictors);

    % Get Indexes of Different Classes of Interest
    labels = data.num_labels;
    zero_idx = labels == 1;
    one_idx = labels == 2;
    two_idx = labels == 3;
    three_idx = labels == 4;

    % Fill Design Matrix
    des_mat(zero_idx,1)                 = 1;
    des_mat(one_idx,2)                  = 1;
    des_mat(two_idx,3)                  = 1;
    des_mat(three_idx,4)                = 1;

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
