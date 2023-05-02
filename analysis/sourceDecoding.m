%% Source Decoding Pipeline
clear;
close all;
addpath D:\bbarnett\Documents\Zero\spm12\
addpath D:\bbarnett\Documents\Zero\scripts\ZeroMEG\analysis\warping_scripts 

subjects = {
    'sub001'
    'sub002' 
    'sub003'
    'sub004'
    'sub005'
    'sub006'
    %'sub007' %Removed for sleeping and 48% accuracy on arabic task
    'sub008'
    'sub009'
    'sub010'
    'sub011'
    };

occ_acc = [];
fro_acc = [];
par_acc = [];

occ_conf = [];
fro_conf = [];
par_conf = [];

tic
progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};
    
    %% 1. Create Head Model
    
    raw_data_dir = fullfile('D:\bbarnett\Documents\Zero\data\Raw\',subject,'\meg\raw');
    dataSets = str2fullfile(raw_data_dir,'*sf025*');
    raw_data = dataSets{1};

    fids = ft_read_headshape(raw_data);
    fids = ft_convert_units(fids,'mm');

    sens = ft_read_header(raw_data);
    sens = sens.grad;
    sens = ft_convert_units(sens,'mm');

    %figure; ft_plot_sens(sens); hold on; ft_plot_headshape(fids);

    [~, ftpath] = ft_version;
    
    % Load SPM Mesh with 5124 vertices
    load(fullfile(ftpath,...
        'template','headmodel','standard_singleshell.mat'));
    headmodel = vol; clear vol;
    
    headmodel = ft_convert_units(headmodel,'mm');
    
    cfg = [];
    cfg.method = 'fids';
    cfg.verbose = 'no';
    [warped_mesh_t, M1] = param_12_affine(cfg,...
        raw_data,headmodel.bnd);
    
    headmodel_new = headmodel;
    headmodel_new.bnd = warped_mesh_t;
    
    %figure; ft_plot_sens(sens); hold on; ft_plot_headshape(fids); hold on;
    %ft_plot_headmodel(headmodel_new);


    %% Now Source Model
    load(fullfile(ftpath,...
        'template','sourcemodel','standard_sourcemodel3d8mm.mat'));
    sourcemodel = ft_convert_units(sourcemodel,'mm');

    cfg = [];
    cfg.method = 'fids';
    cfg.verbose = 'no';
    [warped_mesh_sourcemodel, ~] = param_12_affine(cfg,...
        raw_data,sourcemodel);

    sourcemodel_new = warped_mesh_sourcemodel;
    inside = sourcemodel_new.inside;
    sourcemodel_new.inside = logical(ones(length(sourcemodel_new.inside),1));

    %figure; ft_plot_sens(sens); hold on; ft_plot_headshape(fids); hold on;
    %ft_plot_headmodel(headmodel_new); hold on; ft_plot_mesh(sourcemodel_new);


    %% Source Analysis

    outputDir = fullfile('D:\bbarnett\Documents\Zero\data\Analysis\Source\',subject);
    if ~isfolder(outputDir);mkdir(outputDir);end

    load(fullfile('D:\bbarnett\Documents\Zero\data\CleanData\',subject,'\dot_trials.mat'));
    cfg = [];
    cfg.channel = 'meg';
    %cfg.latency = [0.1 0.5]; %select latency of interest
    meg_data = ft_selectdata(cfg,dot_trials);
    clear dot_trials
      
    meg_data.grad = sens; 
    cfg = [];
    cfg.trials = meg_data.trialinfo(:,5) == 0 & meg_data.trialinfo(:,4) == 1;
    datazero = ft_selectdata(cfg,meg_data);
    cfg.trials = meg_data.trialinfo(:,5) == 1 & meg_data.trialinfo(:,4) == 1;
    dataone = ft_selectdata(cfg,meg_data);
    cfg.trials = meg_data.trialinfo(:,5) == 2 & meg_data.trialinfo(:,4) == 1;
    datatwo = ft_selectdata(cfg,meg_data);
    cfg.trials = meg_data.trialinfo(:,5) == 3 & meg_data.trialinfo(:,4) == 1;
    datathree = ft_selectdata(cfg,meg_data);
    cfg.trials = meg_data.trialinfo(:,5) == 4 & meg_data.trialinfo(:,4) == 1;
    datafour = ft_selectdata(cfg,meg_data);
    cfg.trials = meg_data.trialinfo(:,5) == 5 & meg_data.trialinfo(:,4) == 1;
    datafive = ft_selectdata(cfg,meg_data);
    
    % Compute Covariance Matrix
    cfg = [];
    cfg.covariance = 'yes';
    avg = ft_timelockanalysis(cfg,meg_data);
    
    clear meg_data 

    cfg.keeptrials = 'yes';
    avgzero = ft_timelockanalysis(cfg,datazero);
    avgone = ft_timelockanalysis(cfg,dataone);
    avgtwo = ft_timelockanalysis(cfg,datatwo);
    avgthree = ft_timelockanalysis(cfg,datathree);
    avgfour = ft_timelockanalysis(cfg,datafour);
    avgfive = ft_timelockanalysis(cfg,datafive);

    clear datazero dataone datatwo datathree datafour datafive

    [u,s,v] = svd(avg.cov);
    d       = -diff(log10(diag(s)));
    d       = d./std(d);
    kappa   = find(d>5,1,'first');

    %Calculate spatial filter for each voxel over all data
    cfg = [];
    cfg.method = 'lcmv';
    cfg.sourcemodel = sourcemodel_new;
    cfg.headmodel = headmodel_new;
    cfg.lcmv.keepfilter = 'yes';
    cfg.lcmv.kappa = kappa;
    cfg.lcmv.lambda = '5%'; %try changing this - and try changing kappa
    cfg.lcmv.weightnorm = 'unitnoisegain';
    cfg.lcmv.fixedori = 'yes'; %try changing this
    cfg.channel = {'MEG'};
    cfg.senstype = 'MEG';
    sourceavg = ft_sourceanalysis(cfg, avg);
    sourceavg.pos = sourcemodel.pos; %set grid positions back to template sourcemodel grid
    
    clear sourcemodel_new headmodel_new sourcemodel headmodel
    
    %load atlas
    atlas = ft_read_atlas('..\..\..\fieldtrip-master-MVPA\template\atlas\aal\ROI_MNI_V4.nii');
    %interpolate atlas onto sourcemodel
    cfg = [];
    cfg.parameter = 'tissue';
    cfg.interpmethod = 'nearest';
    atlas_int = ft_sourceinterpolate(cfg,atlas,sourceavg);
    
    %Get the virtual channels
    cfg = [];
    cfg.pos = sourceavg.pos;
    sourcezero = ft_virtualchannel(cfg,avgzero,sourceavg); %using filters built from all conditions
    sourceone = ft_virtualchannel(cfg,avgone,sourceavg);
    sourcetwo = ft_virtualchannel(cfg,avgtwo,sourceavg);
    sourcethree = ft_virtualchannel(cfg,avgthree,sourceavg);
    sourcefour = ft_virtualchannel(cfg,avgfour,sourceavg);
    sourcefive = ft_virtualchannel(cfg,avgfive,sourceavg);
    
    mkdir(fullfile('D:\bbarnett\Documents\Zero\data/Analysis/MEG/Source/',subject,'virtualchannels','dots'));



    save(fullfile('D:\bbarnett\Documents\Zero\data/Analysis/MEG/Source/',subject,'virtualchannels','dots','sourcezero.mat'),"sourcezero")
    save(fullfile('D:\bbarnett\Documents\Zero\data/Analysis/MEG/Source/',subject,'virtualchannels','dots','sourceone.mat'),"sourceone")
    save(fullfile('D:\bbarnett\Documents\Zero\data/Analysis/MEG/Source/',subject,'virtualchannels','dots','sourcetwo.mat'),"sourcetwo")
    save(fullfile('D:\bbarnett\Documents\Zero\data/Analysis/MEG/Source/',subject,'virtualchannels','dots','sourcethree.mat'),"sourcethree")
    save(fullfile('D:\bbarnett\Documents\Zero\data/Analysis/MEG/Source/',subject,'virtualchannels','dots','sourcefour.mat'),"sourcefour")
    save(fullfile('D:\bbarnett\Documents\Zero\data/Analysis/MEG/Source/',subject,'virtualchannels','dots','sourcefive.mat'),"sourcefive")

    clear avgzero avgone avgtwo avgthree avgfour avgfive sourceavg
%{
    %Get Index of channels in specific atlas label
    occ_rois = {'Calcarine_L'	'Calcarine_R'	'Cuneus_L'	'Cuneus_R'	'Lingual_L'	'Lingual_R'	'Occipital_Sup_L'	'Occipital_Sup_R'	'Occipital_Mid_L'	'Occipital_Mid_R'	'Occipital_Inf_L'	'Occipital_Inf_R'	'Fusiform_L'	'Fusiform_R'};
    occ_indx = find(contains(atlas.tissuelabel,occ_rois)); %occipital channels
    %Get data from only these channels
    sourcezero_occ = sourcezero.trial(:,occ_indx,:);
    sourceone_occ = sourceone.trial(:,occ_indx,:);
    sourcetwo_occ = sourcetwo.trial(:,occ_indx,:);
    sourcethree_occ = sourcethree.trial(:,occ_indx,:);
    sourcefour_occ = sourcefour.trial(:,occ_indx,:);
    sourcefive_occ = sourcefive.trial(:,occ_indx,:);

    
    %combine conditions
    X = [sourcezero_occ;sourceone_occ;sourcetwo_occ;sourcethree_occ;sourcefour_occ;sourcefive_occ];
    %create labels
    zero_labels = ones(1,size(sourcezero_occ,1));
    one_labels = ones(1,size(sourceone_occ,1))+1;
    two_labels = ones(1,size(sourcetwo_occ,1))+2;
    three_labels = ones(1,size(sourcethree_occ,1))+3;
    four_labels = ones(1,size(sourcefour_occ,1))+4;
    five_labels = ones(1,size(sourcefive_occ,1))+5;

    Y = [zero_labels one_labels two_labels three_labels four_labels five_labels]';
    
    %smooth data
    smoothed_X = zeros(size(X));
    for trial = 1:size(X,1)
        smoothed_X(trial,:,:) = ft_preproc_smooth(squeeze(X(trial,:,:)),7);
    end


    %Decode!
    cfgS = [];
    cfgS.classifier = 'multiclass_lda';
    cfgS.metric = {'acc' 'confusion'};
    cfgS.preprocess ={'undersample','average_samples'};
    cfgS.repeat = 1;
    cfgS.feedback = true;
    [results_dot_occ,~] = mv_classify(cfgS,smoothed_X,Y); 

    %Plot accuracy
    %figure;plot(sourcezero.time,results_dot_occ); hold on;
    %yline(1/6,'--r');ylim([0 0.7])
    
    clear sourcezero_occ sourceone_occ sourcetwo_occ sourcethree_occ sourcefour_occ sourcefive_occ
%}

    %Get Index of channels in specific atlas label
    fro_indx = find(ismember(atlas_int.tissue,find(contains(atlas_int.tissuelabel,'front','IgnoreCase',true)))); % where x is the number of your choice

    %Get data from only these channels
    sourcezero_fro = sourcezero.trial(:,fro_indx,:);
    sourceone_fro = sourceone.trial(:,fro_indx,:);
    sourcetwo_fro = sourcetwo.trial(:,fro_indx,:);
    sourcethree_fro = sourcethree.trial(:,fro_indx,:);
    sourcefour_fro = sourcefour.trial(:,fro_indx,:);
    sourcefive_fro = sourcefive.trial(:,fro_indx,:);

    %combine two conditions
    X = [sourcezero_fro;sourceone_fro;sourcetwo_fro;sourcethree_fro;sourcefour_fro;sourcefive_fro];
    zero_labels = ones(1,size(sourcezero_fro,1));
    one_labels = ones(1,size(sourceone_fro,1))+1;
    two_labels = ones(1,size(sourcetwo_fro,1))+2;
    three_labels = ones(1,size(sourcethree_fro,1))+3;
    four_labels = ones(1,size(sourcefour_fro,1))+4;
    five_labels = ones(1,size(sourcefive_fro,1))+5;

    Y = [zero_labels one_labels two_labels three_labels four_labels five_labels]';
    

    %smooth data
    smoothed_X = zeros(size(X));
    for trial = 1:size(X,1)
        smoothed_X(trial,:,:) = ft_preproc_smooth(squeeze(X(trial,:,:)),7);
    end

    %Decode!
    cfgS = [];
    cfgS.classifier = 'multiclass_lda';
    cfgS.metric = {'acc' 'confusion'};
    cfgS.preprocess ={'undersample','average_samples'};
    cfgS.repeat = 1;
    cfgS.feedback = true;
    [results_dot_fro,~] = mv_classify(cfgS,smoothed_X,Y); 

    %Plot accuracy
    %figure;plot(sourcezero.time,results_dot_fro); hold on;
    %yline(1/6,'--r');ylim([0 0.7]);

    clear sourcezero_fro sourceone_fro sourcetwo_fro sourcethree_fro sourcefour_fro sourcefive_fro X smoothed_X

    %Get Index of channels in specific atlas label
    par_rois = {'Parietal_Sup_L'	'Parietal_Sup_R'	'Parietal_Inf_L'	'Parietal_Inf_R' 'SupraMarginal_L'	'SupraMarginal_R'	'Angular_L'	'Angular_R'};
    par_indx = find(ismember(atlas_int.tissue,find(contains(atlas_int.tissuelabel,par_rois)))); 
    
    %Get data from only these channels
    sourcezero_par = sourcezero.trial(:,par_indx,:);
    sourceone_par = sourceone.trial(:,par_indx,:);
    sourcetwo_par = sourcetwo.trial(:,par_indx,:);
    sourcethree_par = sourcethree.trial(:,par_indx,:);
    sourcefour_par = sourcefour.trial(:,par_indx,:);
    sourcefive_par = sourcefive.trial(:,par_indx,:);
    %combine two conditions
    X = [sourcezero_par;sourceone_par;sourcetwo_par;sourcethree_par;sourcefour_par;sourcefive_par];
    

    %smooth data
    smoothed_X = zeros(size(X));
    for trial = 1:size(X,1)
        smoothed_X(trial,:,:) = ft_preproc_smooth(squeeze(X(trial,:,:)),7);
    end

    %Decode!
    [results_dot_par,~] = mv_classify(cfgS,smoothed_X,Y); 

    %Plot accuracy
    %figure;plot(sourcezero.time,results_dot_par); hold on;
    %yline(1/6,'--r');ylim([0 0.7]);

    clear sourcezero_par sourceone_par sourcetwo_par sourcethree_par sourcefour_par sourcefive_par X smoothed_X

    %occ_acc = [occ_acc results_dot_occ{1}];
    fro_acc = [fro_acc results_dot_fro{1}];
    par_acc = [par_acc results_dot_par{1}];

    %occ_conf = [occ_conf results_dot_occ{2}];
    fro_conf = [fro_conf results_dot_fro{2}];
    par_conf = [par_conf results_dot_par{2}];

    clear results_dot_fro results_dot_par

    progressbar(subj/length(subjects));
end
toc

%group accuracies over time
mean_occ = mean(occ_acc,2);
mean_par = mean(par_acc,2);
mean_fro = mean(fro_acc,2);

figure;plot(sourcezero.time,mean_occ); hold on;
yline(1/6,'--r'); xline(0,'--'); title('Occipital Source Decoding')

figure;plot(sourcezero.time,mean_par); hold on;
yline(1/6,'--r');xline(0,'--');title('Parietal Source Decoding')

figure;plot(sourcezero.time,mean_fro); hold on;
yline(1/6,'--r');xline(0,'--');title('Frontal Source Decoding')




