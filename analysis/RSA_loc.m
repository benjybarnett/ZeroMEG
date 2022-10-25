function  RSA_loc(cfg0,subject)
    
%function to extract betas vectors needed to form neural RDM.
%Produces a beta vector of Nsensor length for each condition at each time
%point
     disp('loading..')
    disp(subject)
    data = load(fullfile(cfg0.root,'CleanData',subject,'data.mat'));
    data = data.data;  
    
    trls = data.trialinfo(:,2) ==1;% & data.trialinfo(:,3) > 0;
    cfgS = [];
    cfgS.trials =trls;
    data = ft_selectdata(cfgS,data);

    cfgT = [];
    cfgT.keeptrials = 'yes';
    cfgT.channel = cfg0.channels;
    tl_data = ft_timelockanalysis(cfgT, data);
    
    %create design matrix of dummy coded predictors
    trial_info = tl_data.trialinfo;
    des_mat = zeros(length(trial_info),cfg0.num_predictors);
    for trl = 1:length(trial_info)
        
        des_mat(trl,1+trial_info(trl,3)) = 1;

    end

    %get betas
    cfg = [];
    cfg.confound = des_mat;
    cfg.normalize = 'false';
    cfg.output = 'beta';
    betas = ft_regressconfound(cfg,tl_data);
    betas = betas.beta;
    
    
    %create neural RDM for each time point
    nRDMs = {};
    for time = 1:size(betas,3)
        corrs = pdist(betas(:,:,time),'correlation');
        rdm = squareform(corrs);
        nRDMs(time) = {rdm};
    end
    
    
    %smooth nRDM
    nRDMs = cell2mat(permute(nRDMs,[1,3,2]));
    smoothnRDMs =zeros(size(nRDMs));
    window_sz = 60/4; %(window in ms/downsampling rate)
    smooth_filter = unifpdf(1:window_sz,1,window_sz);
    for i = 1:size(nRDMs,1)
        for j = 1:size(nRDMs,2)
            smoothnRDMs(i,j,:) = conv(squeeze(nRDMs(i,j,:)),smooth_filter,'same');
        end
    end
    
   
    %number rdm
    mRDM = load(fullfile(cfg0.mRDM_path,[cfg0.mRDM_file,'.mat']));
    mRDM = mRDM.rdm;
    
    idxs = itril(cfg0.num_predictors,-1); %indices of lower triangle without diagonal
    mRDM = mRDM(idxs);
     % Correlate neural RDM with model RDM
    rhos = [];
    for n = 1:size(nRDMs,3)
        nRDM = smoothnRDMs(:,:,n);
        nRDM = nRDM(idxs);

        rho = corr(nRDM,mRDM,'Type','Kendall');
        rhos = [rhos rho];
        
    end

    
    %baseline correct
    
    bl_rho = mean(rhos(1:60)); %% Edit this index if altering downsampling freq
    rhos = rhos - bl_rho;
    
    figure; plot(rhos)

    %save
    outputDir = fullfile(cfg0.root,cfg0.output_path,'RSA',subject,cfg0.mRDM_file);
    disp(outputDir)
    if ~exist(outputDir,'dir'); mkdir(outputDir); end 
    save(fullfile(outputDir,'rhos_no_diag.mat'), 'rhos')
    
end
