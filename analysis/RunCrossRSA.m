function rhos = RunCrossRSA(cfg0,tl_data,des_mat)
%Function runs an RSA across time using the timelocked data (trials x channels x time) 
%and trial design matrix (trials x condition) with dummy coded predictors
%(i.e. 1 in condition column when trial is an instance of that condition)
%Specifically for cross condition RSA, where we want the lower quarter of the full rdm.

    %% Get Betas for RSA

    %Produces a [Classes x Channels x Time] Matrix of Betas
    cfg = [];
    cfg.confound = des_mat;
    cfg.normalize = 'no';
    cfg.output = 'beta';
    betas = ft_regressconfound(cfg,tl_data);
    betas = betas.beta;    
    
    %% Create Neural RDM for Each Time Point
    nRDMs = {};
    for time = 1:size(betas,3)
        corrs = pdist(betas(:,:,time),'correlation');
        rdm = squareform(corrs);
        nRDMs(time) = {rdm};
    end

    %Smooth neural RDMs
    nRDMs = cell2mat(permute(nRDMs,[1,3,2])); %change to [Classes x Classes x Time] matrix
    smoothnRDMs =zeros(size(nRDMs));
    window_sz = 60/4; %(window in ms/downsampling rate)
    smooth_filter = unifpdf(1:window_sz,1,window_sz);
    for i = 1:size(nRDMs,1)
        for j = 1:size(nRDMs,2)
            smoothnRDMs(i,j,:) = conv(squeeze(nRDMs(i,j,:)),smooth_filter,'same');
        end
    end
    
    %% Load the Model RDM
    mRDM = load(fullfile(cfg0.mRDM_path,[cfg0.mRDM_file,'.mat']));
    mRDM = struct2cell(mRDM); mRDM = mRDM{1};  
    mRDM = mRDM(end-(cfg0.num_predictors/2)+1:end,1:cfg0.num_predictors/2);% get lower left quadrant (i.e. cross-condition section)
    mRDM = mRDM(:);
    if cfg0.removeDiag 
        disp('Removing diagonal of model RDM')
         mRDM(1:((cfg0.num_predictors/2)+1):end) = [];
    end


    %% Correlate Neural RDM with Model RDM
    rhos = [];
    for n = 1:size(nRDMs,3)
        nRDM = smoothnRDMs(:,:,n);
        nRDM = nRDM(end-(cfg0.num_predictors/2)+1:end,1:cfg0.num_predictors/2);% get lower left quadrant (i.e. cross-condition section)
        nRDM = nRDM(:);
        if cfg0.removeDiag
            nRDM(1:((cfg0.num_predictors/2)+1):end) = [];
        end
        rho = corr(nRDM,mRDM,'Type','Kendall');
        rhos = [rhos rho];
    end
    
    %% Baseline Correct Rho Values
    
    time = tl_data.time;
    stim_on = find(time == 0);
    bl_rho = mean(rhos(1:stim_on));
    rhos = rhos - bl_rho;
    
    
end