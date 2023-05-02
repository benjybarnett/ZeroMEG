%% Source Reconstruction Pipeline
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
all_subjects = [];
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

    figure; ft_plot_sens(sens); hold on; ft_plot_headshape(fids); hold on;
    ft_plot_headmodel(headmodel_new); hold on; ft_plot_mesh(sourcemodel_new);


    %% Source Analysis

    outputDir = fullfile('D:\bbarnett\Documents\Zero\data\Analysis\Source\',subject);
    if ~isfolder(outputDir);mkdir(outputDir);end

    load(fullfile('D:\bbarnett\Documents\Zero\data\CleanData\',subject,'\dot_trials.mat'));
    cfg = [];
    cfg.channel = 'meg';
    cfg.latency = [0.1 0.5]; %select latency of interest
    meg_data = ft_selectdata(cfg,dot_trials);
    clear dot_trials
      
    meg_data.grad = sens; 
    cfg = [];
    cfg.trials = meg_data.trialinfo(:,5) == 0 & meg_data.trialinfo(:,4) == 1;
    datazero = ft_selectdata(cfg,meg_data);
    cfg.trials = meg_data.trialinfo(:,5) < 5 & meg_data.trialinfo(:,4) == 1;
    datanotzero = ft_selectdata(cfg,meg_data);
    
    % Compute Covariance Matrix
    cfg = [];
    cfg.covariance = 'yes';
    avg = ft_timelockanalysis(cfg,meg_data);
    
    cfg.keeptrials = 'yes';
    avgzero = ft_timelockanalysis(cfg,datazero);
    avgnotzero = ft_timelockanalysis(cfg,datanotzero);
    
    %Calculate spatial filter for each voxel over all data
    cfg = [];
    cfg.method = 'lcmv';
    cfg.sourcemodel = sourcemodel_new;
    cfg.headmodel = headmodel_new;
    cfg.lcmv.keepfilter = 'yes';
    cfg.lcmv.lambda = '5%';
    cfg.channel = {'MEG'};
    cfg.senstype = 'MEG';
    sourceavg = ft_sourceanalysis(cfg, avg);
    
    %Now apply this filter to zero and five data separately
    cfg = [];
    cfg.method = 'lcmv';
    cfg.sourcemodel = sourcemodel_new;
    cfg.sourcemodel.filter = sourceavg.avg.filter;
    cfg.headmodel = headmodel_new;
    sourcezero = ft_sourceanalysis(cfg, avgzero);
    sourcenotzero = ft_sourceanalysis(cfg, avgnotzero);
    
    %Now contrast two conditions
    cfg = [];
    cfg.operation = '(x1-x2)./x2';
    cfg.parameter = 'pow';
    source_diff = ft_math(cfg,sourcezero,sourcenotzero);
    
    
    %% Plot sources on Anatomical MRI
    % Load MRI MNI template
    mri = ft_read_mri('D:\bbarnett\Documents\Zero\fieldtrip-master-MVPA\template\anatomy\single_subj_T1.nii');

    %replace individual subjects' source positions with the normalized positions of the template sourcemodel
    source_diff.pos = sourcemodel.pos;

    %Now plot on top of anatomical
    cfg               = [];
    cfg.method        = 'surface';
    cfg.funparameter  = 'pow';
    cfg.funcolormap = 'jet';
    ft_sourceplot(cfg, source_diff);
    
    %% Save 
    cfg.filename = fullfile(outputDir,strcat('source_',subject,'_dot_mni'));
    cfg.filetype = 'nifti';
    cfg.parameter = 'pow';
    %ft_s ourcewrite(cfg,source_diff);
    
    all_subjects = [all_subjects source_diff];
  

end

%Avg over subjects
grandavg = ft_sourcegrandaverage(cfg, all_subjects(1),all_subjects(2),all_subjects(3),all_subjects(4),...
    all_subjects(5),all_subjects(6),all_subjects(7),all_subjects(8),all_subjects(9));

grandavg.mask = grandavg.pow > max(grandavg.pow(:))*.7; % 30 % of maximum

cfg               = [];
cfg.method        = 'surface';
cfg.funparameter  = 'pow';
cfg.funcolormap = 'jet';
cfg.maskparameter = 'mask';
ft_sourceplot(cfg, grandavg);


%% Arabic

all_subjects = [];
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

    %figure; ft_plot_sens(sens); hold on; ft_plot_headshape(fids); hold on;
    %ft_plot_headmodel(headmodel_new); hold on; ft_plot_mesh(sourcemodel_new);


    %% Source Analysis

    outputDir = fullfile('D:\bbarnett\Documents\Zero\data\Analysis\Source\',subject);
    if ~isfolder(outputDir);mkdir(outputDir);end

    load(fullfile('D:\bbarnett\Documents\Zero\data\CleanData\',subject,'\arabic_trials.mat'));
    cfg = [];
    cfg.channel = 'meg';
    cfg.latency = [0.1 0.5]; %select latency of interest
    meg_data = ft_selectdata(cfg,arabic_trials);
    clear arabic_trials
      
    meg_data.grad = sens; 
    cfg = [];
    cfg.trials = meg_data.trialinfo(:,4) == 5;
    datazero = ft_selectdata(cfg,meg_data);
    cfg.trials = meg_data.trialinfo(:,4) < 5;
    datanotzero = ft_selectdata(cfg,meg_data);
    
    % Compute Covariance Matrix
    cfg = [];
    cfg.covariance = 'yes';
    avg = ft_timelockanalysis(cfg,meg_data);
    
    cfg.keeptrials = 'yes';
    avgzero = ft_timelockanalysis(cfg,datazero);
    avgnotzero = ft_timelockanalysis(cfg,datanotzero);
    
    %Calculate spatial filter for each voxel over all data
    cfg = [];
    cfg.method = 'lcmv';
    cfg.sourcemodel = sourcemodel_new;
    cfg.headmodel = headmodel_new;
    cfg.lcmv.keepfilter = 'yes';
    cfg.lcmv.lambda = '5%';
    cfg.channel = {'MEG'};
    cfg.senstype = 'MEG';
    sourceavg = ft_sourceanalysis(cfg, avg);
    
    %Now apply this filter to zero and five data separately
    cfg = [];
    cfg.method = 'lcmv';
    cfg.sourcemodel = sourcemodel_new;
    cfg.sourcemodel.filter = sourceavg.avg.filter;
    cfg.headmodel = headmodel_new;
    sourcezero = ft_sourceanalysis(cfg, avgzero);
    sourcenotzero = ft_sourceanalysis(cfg, avgnotzero);
    
    %Now contrast two conditions
    cfg = [];
    cfg.operation = '(x1-x2)./x2';
    cfg.parameter = 'pow';
    source_diff = ft_math(cfg,sourcezero,sourcenotzero);
    
    
    %% Plot sources on Anatomical MRI
    % Load MRI MNI template
    mri = ft_read_mri('D:\bbarnett\Documents\Zero\fieldtrip-master-MVPA\template\anatomy\single_subj_T1.nii');

    %replace individual subjects' source positions with the normalized positions of the template sourcemodel
    source_diff.pos = sourcemodel.pos;

    %Now plot on top of anatomical
    cfg               = [];
    cfg.method        = 'surface';
    cfg.funparameter  = 'pow';
    cfg.funcolormap = 'jet';
    %ft_sourceplot(cfg, source_diff);
    
    %% Save 
    cfg.filename = fullfile(outputDir,strcat('source_',subject,'_arabic_mni'));
    cfg.filetype = 'nifti';
    cfg.parameter = 'pow';
    %ft_sourcewrite(cfg,source_diff);
    
    all_subjects = [all_subjects source_diff];
  

end
%Avg over subjects
grandavg = ft_sourcegrandaverage(cfg, all_subjects(1),all_subjects(2),all_subjects(3),all_subjects(4),...
    all_subjects(5),all_subjects(6),all_subjects(7),all_subjects(8));
mask = g
cfg               = [];
cfg.method        = 'surface';
cfg.funparameter  = 'pow';
cfg.funcolormap = 'jet';
ft_sourceplot(cfg, grandavg);
