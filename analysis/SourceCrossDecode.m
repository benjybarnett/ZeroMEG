function SourceCrossDecode(cfg0,subject)

    % SourceDecode Function
    % 

    %Description: Loads Virtual Channels previusly computed in within-condition decoding function.
    %Then performs cross-modality decoding within a specified atlas ROI.

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
    
    
    disp('Loading Previously Computed Virtual Channels')
    aChannels = load(fullfile(cfg0.root,cfg0.vChanOutDir,'arabic',cfg0.roi_name,subject,'vChannels.mat'),'vChannels');
    dChannels = load(fullfile(cfg0.root,cfg0.vChanOutDir,'dots',cfg0.roi_name,subject,'vChannels.mat'),'vChannels');
    aChannels = aChannels.vChannels;
    dChannels = dChannels.vChannels;

    %Smooth Data
    aChannels.smoothTrial  = {};
    for trial = 1:numel(aChannels.trial)
        aChannels.smoothTrial{trial} = ft_preproc_smooth(squeeze(aChannels.trial{trial}),cfg0.tSmooth);
    end
    aChannels.trial = aChannels.smoothTrial;
    dChannels.smoothTrial  = {};
    for trial = 1:numel(dChannels.trial)
        dChannels.smoothTrial{trial} = ft_preproc_smooth(squeeze(dChannels.trial{trial}),cfg0.tSmooth);
    end
    dChannels.trial = dChannels.smoothTrial;

    %PCA  %%Not adapted for cross decoding yet
    %{
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
    %}

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
    %% Get Trial x Channels x Time Matrix For Each Task
    dot_data = zeros(size(dChannels.trial,2),size(dChannels.label,1),size(dChannels.time{1},2));
    for trl = 1:length(dChannels.trial)
        dot_data(trl,:,:) = dChannels.trial{trl};
    end

    arabic_data = zeros(size(aChannels.trial,2),size(aChannels.label,1),size(aChannels.time{1},2));
    for trl = 1:length(aChannels.trial)
        arabic_data(trl,:,:) = aChannels.trial{trl};
    end

    %% Select Same Trial Length
    [~,ind] = ismember(aChannels.time{1}, dChannels.time{1});
    dot_data = dot_data(:,:,ind(1):end);
    

    cfgS = [];
    cfgS.classifier = 'multiclass_lda';
    cfgS.metric = cfg0.metric;
    cfgS.preprocess ={'undersample','average_samples'};
    cfgS.repeat = 1;
    [results_arabic,~] = mv_classify_timextime(cfgS,arabic_data,aChannels.trialinfo+1,dot_data,dChannels.trialinfo+1);
    [results_dot,~] = mv_classify_timextime(cfgS,dot_data,dChannels.trialinfo+1,arabic_data,aChannels.trialinfo+1);

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
    save(fullfile(outputDir,'train_arabic.mat'),'results_arabic');
    save(fullfile(outputDir,'train_dots.mat'),"results_dot");

    clear results_arabic results_dot dot_data arabic_data aChannels dChannels
end