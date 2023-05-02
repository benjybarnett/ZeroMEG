function vChannels = SourceDecode(cfg0,subject)

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
    % The function outputs the Virtual Channels data over time for all trial conditions
    
    %Author: Benjy Barnett 2023

    %Perform Forward Modelling
    cfg = [];
    cfg.rawDir = cfg0.rawDir;
    [headmodel,sourcemodel,grad,pos,template_source] = ForwardModel(cfg,subject);

    %Perform Source Analysis - Get Virtual Channels Per Condition
    if isfield(cfg0,'vChannels')
        vChannels = cfg0.vChannels;
        disp('Loading Virtual Channels')
    else
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
        vChannels = SourceAnalysis(cfg,subject); %maybe add atlas functioning to this method
    end

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

    %Load in the virtual channels for this ROI (Decoding Data and Labels)
    X = [];
    Y = [];
    for cond = 1:length(vChannels)
        source = vChannels{cond};
        source_roi = source.trial(:,roi_idx,:);
        X = [X; source_roi];
        Y = [Y; zeros(size(source_roi,1),1)+cond];
    end
    
    clear atlas_int 

    %Smooth Data
    smoothed_X = zeros(size(X));
    for trial = 1:size(X,1)
        smoothed_X(trial,:,:) = ft_preproc_smooth(squeeze(X(trial,:,:)),cfg0.tSmooth);
    end

    clear X

    %Decode
    cfgS = [];
    cfgS.classifier = 'multiclass_lda';
    cfgS.metric = cfg0.metric;
    cfgS.preprocess ={'undersample','average_samples'};
    cfgS.repeat = 1;
    cfgS.feedback = true;
    [results,~] = mv_classify(cfgS,smoothed_X,Y); 

    %Save
    outputDir = fullfile(cfg0.root,cfg0.outdir,cfg0.roi_name,subject);
    if ~isfolder(outputDir);mkdir(outputDir);end
    save(fullfile(outputDir,'results.mat'),'results');

    clear results smoothed_X Y
end