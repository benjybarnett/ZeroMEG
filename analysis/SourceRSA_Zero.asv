function numcomponent = SourceRSA_Zero(cfg0,subject)

% Function Name: SourceRSA_Zero
%
% Description: This function performs a multivariate pattern analysis using representational similarity analysis (RSA) on virtual channels derived from MEG data. The analysis is performed separately for each subject.
%
%Input:
%     cfg0: A structure containing the configuration parameters for the analysis. The fields of this structure are described below:
%     rawDir: The path to the directory containing the raw MEG data files.
%     root: The path to the root directory for the analysis.
%     vChanOutDir: The name of the directory where the virtual channels will be saved.
%     sensor_data: The name of the file containing the cleaned sensor-level data.
%     condition_trls: A cell array containing the trial labels for each condition.
%     group_size: The number of trials to group together for each condition in order to create the virtual channels.
%     roiLabelIdxs: A cell array containing the indices of the regions of interest (ROIs) to include in the analysis.
%     num_predictors: The number of predictors in the design matrix for the RSA analysis.
%     subject: The ID of the subject to analyze.
%     
% 
% Output:
%
%     None
%     Functionality:
%
%     Performs forward modeling to obtain the head model, source model, gradient information, position information, and template source.
%     Calculates virtual channels for each condition using the SourceAnalysis function and concatenates them into a single data structure.
%     Loads the Automated Anatomical Labeling (AAL) atlas and interpolates it onto the template source model in MNI space.
%     Extracts the tissue labels for the ROIs of interest.
%     Creates a design matrix of dummy-coded predictors based on the trial labels.
%     Computes a trial x virtual channels x time matrix using ft_timelockanalysis.
%     Runs RSA on the trial x virtual channels matrix and the design matrix using the RunRSA function.
%     Saves the results in a directory specified by cfg0.
%Author: Benjy Barnett 2023

    outputDir = fullfile(cfg0.outdir,subject);
    if ~isfolder(outputDir);mkdir(outputDir);end
    
    if ~isfolder(fullfile(cfg0.root,cfg0.vChanOutDir,cfg0.roi_name,subject))
        %Perform Forward Modelling
        cfg = [];
        cfg.rawDir = cfg0.rawDir;
        [headmodel,sourcemodel,grad,pos,template_source] = ForwardModel(cfg,subject);
    
        %Perform Source Analysis - Get Virtual Channels Per Condition
       
        disp('Calculating Virtual Channels')
        cfg = [];
        cfg.outdir = fullfile(cfg0.root,cfg0.vChanOutDir); %cfg0.vChanOutDir = 'Analysis/MEG\Source\virtualchannels\dots';
        cfg.datadir = fullfile(cfg0.root,'CleanData',subject,cfg0.sensor_data);
        cfg.headmodel = headmodel;
        cfg.sourcemodel = sourcemodel;
        cfg.grad = grad;
        cfg.pos = pos;
        cfg.avgSourceOut = 'avgSource.mat';
        cfg.condition_trls = cfg0.condition_trls;
        cfg.group_size = cfg0.group_size;
        vChannels = SourceAnalysis(cfg); 
        %get trial labels
        Y = [];
        for cond = 1:length(vChannels)
            source = vChannels{cond};
            Y = [Y; zeros(size(source.trial,1),1)+cond-1];
        end
        vChannels = ft_appenddata([],vChannels{:}); %concat conditions
        vChannels.trialinfo = Y;
    
        %Load AAL Atlas
        atlas = ft_read_atlas('D:\bbarnett\Documents\ecobrain\fieldtrip-master-MVPA\template\atlas\aal\ROI_MNI_V4.nii');
        %interpolate atlas onto template source model in MNI space
        cfg = [];
        cfg.parameter = 'tissue';
        cfg.interpmethod = 'nearest';
        atlas_int = ft_sourceinterpolate(cfg,atlas,template_source);
        atlas_int.tissue = atlas_int.tissue(template_source.inside); %just get those points inside skull
        clear atlas allCondSource
        
        %Get Atlas labels for current ROI
        roi_idx = find(ismember(atlas_int.tissue,find(contains(atlas_int.tissuelabel,cfg0.roiLabelIdxs))));
    
        % Select channels in ROI
        cfg = [];
        cfg.channel = roi_idx;
        vChannels = ft_selectdata(cfg,vChannels);

        mkdir(fullfile(cfg0.root,cfg0.vChanOutDir,cfg0.roi_name,subject))
        disp('saving virtual channels')
        save(fullfile(cfg0.root,cfg0.vChanOutDir,cfg0.roi_name,subject,'vChannels.mat'),'vChannels');
    else
        disp('Loading Previously Computed Virtual Channels')
        load(fullfile(cfg0.root,cfg0.vChanOutDir,cfg0.roi_name,subject,'vChannels.mat'),'vChannels')
    end



    %PCA 
    if cfg0.pca 
        covar = zeros(numel(vChannels.label));
        for itrial = 1:numel(vChannels.trial)
            currtrial = vChannels.trial{itrial};
            covar = covar + currtrial*currtrial.';
        end
        [~, D] = eig(covar);
        D = sort(diag(D),'descend');
        D = D ./ sum(D);
        Dcum = cumsum(D);
        numcomponent = find(Dcum>.99,1,'first');
        %figure; screeplot(Dcum,cfg0.roi_name)
        %hold on; xline(numcomponent,'r--');
         
        cfg = [];
        cfg.method = 'pca';
        cfg.demean = 'no';
        cfg.updatesens = 'yes';
        comp = ft_componentanalysis(cfg, vChannels);

        cfg = [];
        cfg.channel = comp.label(1:numcomponent);
        vChannels = ft_selectdata(cfg,comp);
        %{
        cfg = [];
        cfg.updatesens = 'yes';
        cfg.component = comp.label(numcomponent:end);
        vChannels = ft_rejectcomponent(cfg, comp,vChannels);
        %}
    else
        numcomponent = 0;
    end
        


    %% Create Design Matrix of Dummy Coded Predictors
    Y = vChannels.trialinfo;
    des_mat = zeros(length(Y),cfg0.num_predictors);

    % Get Indexes of Different Classes of Interest
    zero_idx = Y == 0;
    one_idx = Y == 1;
    two_idx = Y == 2;
    three_idx = Y == 3;
    four_idx = Y == 4;
    five_idx = Y == 5;

    % Fill Design Matrix
    des_mat(zero_idx,1)                 = 1;
    des_mat(one_idx,2)                  = 1;
    des_mat(two_idx,3)                  = 1;
    des_mat(three_idx,4)                = 1;
    des_mat(four_idx,5)                 = 1;
    des_mat(five_idx,6)                 = 1;

    %% Get Trial x VirtualChannels x Time matrix
    cfgT = [];
    cfgT.keeptrials = 'yes';
    tl_vChan = ft_timelockanalysis(cfgT, vChannels);
    
    clear vChannels

    %% Run RSA
    rhos = RunRSA(cfg0,tl_vChan,des_mat);

    %Save
    if cfg0.pca
        outputDir = fullfile(cfg0.root,cfg0.outdir,cfg0.mRDM_file,cfg0.roi_name,'pca',subject);
    else
        outputDir = fullfile(cfg0.root,cfg0.outdir,cfg0.mRDM_file,cfg0.roi_name,subject);
    end
    if ~isfolder(outputDir);mkdir(outputDir);end
    save(fullfile(outputDir,'rhos.mat'),'rhos');

    clear tl_vChan rhos
end