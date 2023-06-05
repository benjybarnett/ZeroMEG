function SourceDecode(cfg0,subject)

    % SourceDecode Function
    % 

    %Description: Performs forward and inverse modelling, creating virtual channels for each
    %condition. Then performs decoding within a specified atlas ROI.

    % INPUT:

    % The cfg0 struct includes the following fields:
    % 
    % root: the root directory for the data analysis
    % rawDir: the directory containing the raw MEG data
    % vChanOutDir: the directory for output virtual channels
    % roiLabelIdxs: an array specifying the indices of the regions of interest (ROIs) to analyze
    % metric: the performance metric to use for classification
    % tSmooth: the time window (in seconds) to use for smoothing the data
    % The function performs forward modeling and source analysis on the MEG data for the specified subject, and extracts virtual channels for each of the specified ROIs. It then uses a linear discriminant analysis (LDA) classifier to decode the trial conditions (specified in cfg.condition_trls) based on the activity patterns in the virtual channels. The resulting decoding accuracy is saved to a results.mat file in the subject's output directory.
    % 
    
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

    %Smooth Data
    vChannels.smoothTrial  = {};
    for trial = 1:numel(vChannels.trial)
        vChannels.smoothTrial{trial} = ft_preproc_smooth(squeeze(vChannels.trial{trial}),cfg0.tSmooth);
    end
    vChannels.trial = vChannels.smoothTrial;

    %PCA 
    if cfg0.pca 
        disp('Doing PCA')
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

    %Decode
    %{
    cfgS = [];
    cfgS.classifier = 'multiclass_lda';
    cfgS.metric = cfg0.metric;
    cfgS.preprocess ={'undersample'};%averaging samples before source recon
    cfgS.repeat = 1;
    cfgS.feedback = true;
    cfg.sample_dimension = 1;
    cfg.feature_dimension = 2;
    cfgS.generalization_dimension = 3;
    [results,~] = mv_classify(cfgS,smoothed_X,Y); 
    %}
    cfg = [] ;
    cfg.method          = 'mvpa';
    cfg.avgovertime     = 'no';
    cfg.design          = vChannels.trialinfo;
    %cfg.design = cfg.design(randperm(length(cfg.design)));
    cfg.features        = 'chan';
    cfg.mvpa            = [];
    cfg.mvpa.classifier = 'multiclass_lda';
    cfg.mvpa.metric     = {'accuracy','confusion'};
    cfg.mvpa.k          = 5;
    cfg.mvpa.repeat    = 1;
    cfg.mvpa.preprocess    = {'undersample'};
    cfg.generalize = 'time';
    results = ft_timelockstatistics(cfg, vChannels);
   
    %{
    %% Confusion Matrix Averaged Over Time
    % Average over user-specified times
    if contains(cfg0.sensor_data,'dot')
        time = load('dot_time.mat');
        time = time.dot_time;
    elseif contains(cfg0.sensor_data,'arabic')
        time = load('arabic_time.mat');
        time = time.arabic_time;
    end

    beg = find(time == cfg0.timepoints(1));
    fin =  find(time == cfg0.timepoints(2));

    avg_X = squeeze(mean(smoothed_X(:,:,beg:fin),3));
    
    %Decode
    cfgS = [];
    cfgS.classifier = 'multiclass_lda';
    cfgS.metric = 'confusion';
    cfgS.preprocess ={'undersample'};%averaging samples before source recon
    cfgS.repeat = 1;
    cfgS.feedback = true;
    [avg_conf,~] = mv_classify(cfgS,avg_X,Y); 
    clear avg_X
    %}

    %Save
    if cfg0.pca
        outputDir = fullfile(cfg0.root,cfg0.outdir,cfg0.roi_name,'pca',subject);
    else
        outputDir = fullfile(cfg0.root,cfg0.outdir,cfg0.roi_name,subject);
    end
    if ~isfolder(outputDir);mkdir(outputDir);end
    save(fullfile(outputDir,'results.mat'),'results');
    %save(fullfile(outputDir,'avg_conf.mat'),'avg_conf');

    clear results smoothed_X Y
end