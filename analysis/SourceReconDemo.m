%% Source Reconstruction Pipeline
addpath D:\bbarnett\Documents\Zero\spm12\
%% 1. Create Head Model

% Load fMRI MNI template

mri = ft_read_mri('D:\bbarnett\Documents\Zero\fieldtrip-master-MVPA\template\anatomy\single_subj_T1.nii');

%determine if left-to-right or right-to-left
ft_determine_coordsys(mri)

%get fiducial points
raw_data_dir = fullfile('D:\bbarnett\Documents\Zero\data\Raw',subject,'meg','raw');
dataSets = str2fullfile(raw_data_dir,'*SF025*');
ds = dataSets(1);

%head = ft_read_headshape(ds);
%head = ft_convert_units(head,'mm');

%align to ctf
cfg = [];
cfg.method = 'interactive';
cfg.coordsys = 'ctf';
mri_realigned = ft_volumerealign(cfg,mri);


ft_determine_coordsys(mri_realigned)


%segment brain from skull
cfg           = [];
cfg.output    = 'brain';
segmentedmri  = ft_volumesegment(cfg, mri_realigned);
%save segmentedmri segmentedmri

% Build volume conduction model from geometry of brain
cfg = [];
cfg.method='singleshell';
vol = ft_prepare_headmodel(cfg, segmentedmri);

% Visualise
vol = ft_convert_units(vol, 'cm');
sens = ft_read_sens(ds{1}, 'senstype', 'meg');
figure
ft_plot_sens(sens, 'coilshape','point','style', 'r+');

hold on
ft_plot_headmodel(vol);

%% Load MEG Data

%% Zero Project Analysis
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
    };
for subj = 1:length(subjects)
    subject = subjects{subj};

    outputDir = fullfile('D:\bbarnett\Documents\Zero\data\Analysis\Source\',subject);
    if ~isfolder(outputDir);mkdir(outputDir);end

    load(fullfile('D:\bbarnett\Documents\Zero\data\CleanData\',subject,'\dot_trials.mat'));
    cfg = [];
    cfg.channel = 'meg';
    cfg.latency = [0.1 0.5];
    meg_data = ft_selectdata(cfg,dot_trials);
    clear dot_trials
    
    
    %% Compute the leadfield
    cfg = [];
    cfg.channel = meg_data.label;
    cfg.grad = sens;
    cfg.headmodel = vol;
    cfg.reducerank = 2;
    cfg.resolution = 0.8;
    cfg.unit = 'cm';
    cfg.tight = 'yes';
    [grid] = ft_prepare_leadfield(cfg);
    
    %% Source Analysis
    cfg = [];
    cfg.trials = meg_data.trialinfo(:,5) == 0 & meg_data.trialinfo(:,4) == 1;
    datazero = ft_selectdata(cfg,meg_data);
    cfg.trials = meg_data.trialinfo(:,5) > 0 & meg_data.trialinfo(:,4) == 1;
    datanotzero = ft_selectdata(cfg,meg_data);
    
    % Compute Covariance Matrix
    cfg = [];
    cfg.covariance = 'yes';
    cfg.covariancewindow = [0.1 0.5];
    avg = ft_timelockanalysis(cfg,meg_data);
    
    cfg.keeptrials = 'yes';
    avgzero = ft_timelockanalysis(cfg,datazero);
    avgnotzero = ft_timelockanalysis(cfg,datanotzero);
    
    %Calculate spatial filter for each voxel over all data
    cfg = [];
    cfg.method = 'lcmv';
    cfg.sourcemodel = grid;
    cfg.headmodel = vol;
    cfg.lcmv.keepfilter = 'yes';
    cfg.lcmv.lambda = '5%';
    cfg.channel = {'MEG'};
    cfg.senstype = 'MEG';
    sourceavg = ft_sourceanalysis(cfg, avg);
    
    %Now apply this filter to zero and five data separately
    cfg = [];
    cfg.method = 'lcmv';
    cfg.grid = grid;
    cfg.sourcemodel.filter = sourceavg.avg.filter;
    cfg.headmodel = vol;
    sourcezero = ft_sourceanalysis(cfg, avgzero);
    sourcenotzero = ft_sourceanalysis(cfg, avgnotzero);
    
    %Now contrast two conditions
    cfg = [];
    cfg.operation = '(x1-x2)./x2';
    cfg.parameter = 'pow';
    source_diff = ft_math(cfg,sourcenotzero,sourcezero);
    
    
    %% Plot sources on Anatomical MRI
    
    % First align sources with MRI
    cfg              = [];
    cfg.voxelcoord   = 'no';
    cfg.parameter    = 'pow';
    cfg.interpmethod = 'nearest';
    source_int  = ft_sourceinterpolate(cfg, source_diff, mri_realigned);
    
    %Now plot on top of anatomical
    
    source_int.mask = source_int.pow > 0.04; % anything above 0.04
    cfg               = [];
    cfg.method        = 'ortho';
    cfg.funparameter  = 'pow';
    cfg.maskparameter = 'mask';
    %cfg.location = [-42 -18 67];
    cfg.funcolormap = 'jet';
    %cfg.latency = [0.1 0.5];
    %ft_sourceplot(cfg, source_diff,mri_realigned);
    
    %% Save 
    %This saves in CTF coords. 
    cfg = [];
    cfg.filename = fullfile(outputDir,strcat('source_',subject,'_dot'));
    cfg.filetype = 'nifti';
    cfg.parameter = 'pow';
    ft_sourcewrite(cfg,source_int);
    
    cfg=[];
    cfg.parameter = 'anatomy';
    cfg.filetype = 'nifti';
    cfg.filename = 'CTFStruct';
    cfg.datatype = 'double';
    %ft_volumewrite(cfg,mri_realigned);
    
    %Normalise into MNI coordinates for group analysis
    cfg = [];
    cfg.nonlinear = 'no';
    source_mni_norm = ft_volumenormalise(cfg,source_int);
    
    cfg = [];
    cfg.filename = fullfile(outputDir,strcat('source_',subject,'_dot_mni'));
    cfg.filetype = 'nifti';
    cfg.parameter = 'pow';
    ft_sourcewrite(cfg,source_mni_norm);
    
    
  

end




%% Arabic
for subj = 1:length(subjects)
    subject = subjects{subj};

    outputDir = fullfile('D:\bbarnett\Documents\Zero\data\Analysis\Source\',subject);
    if ~isfolder(outputDir);mkdir(outputDir);end

    load(fullfile('D:\bbarnett\Documents\Zero\data\CleanData\',subject,'\arabic_trials.mat'));
    cfg = [];
    cfg.channel = 'meg';
    cfg.latency = [0.1 0.5];
    meg_data = ft_selectdata(cfg,arabic_trials);
    clear arabic_trials
    
    
    %% Compute the leadfield
    cfg = [];
    cfg.channel = meg_data.label;
    cfg.grad = sens;
    cfg.headmodel = vol;
    cfg.reducerank = 2;
    cfg.resolution = 0.8;
    cfg.unit = 'cm';
    cfg.tight = 'yes';
    [grid] = ft_prepare_leadfield(cfg);
    
    %% Source Analysis
    cfg = [];
    cfg.trials = meg_data.trialinfo(:,4) == 0;
    datazero = ft_selectdata(cfg,meg_data);
    cfg.trials = meg_data.trialinfo(:,4) > 0;
    datanotzero = ft_selectdata(cfg,meg_data);
    
    % Compute Covariance Matrix
    cfg = [];
    cfg.covariance = 'yes';
    cfg.covariancewindow = [0.1 0.5];
    avg = ft_timelockanalysis(cfg,meg_data);
    
    cfg.keeptrials = 'yes';
    avgzero = ft_timelockanalysis(cfg,datazero);
    avgnotzero = ft_timelockanalysis(cfg,datanotzero);
    
    %Calculate spatial filter for each voxel over all data
    cfg = [];
    cfg.method = 'lcmv';
    cfg.sourcemodel = grid;
    cfg.headmodel = vol;
    cfg.lcmv.keepfilter = 'yes';
    cfg.lcmv.lambda = '5%';
    cfg.channel = {'MEG'};
    cfg.senstype = 'MEG';
    sourceavg = ft_sourceanalysis(cfg, avg);
    
    %Now apply this filter to zero and five data separately
    cfg = [];
    cfg.method = 'lcmv';
    cfg.grid = grid;
    cfg.sourcemodel.filter = sourceavg.avg.filter;
    cfg.headmodel = vol;
    sourcezero = ft_sourceanalysis(cfg, avgzero);
    sourcenotzero = ft_sourceanalysis(cfg, avgnotzero);
    
    %Now contrast two conditions
    cfg = [];
    cfg.operation = '(x1-x2)./x2';
    cfg.parameter = 'pow';
    source_diff = ft_math(cfg,sourcenotzero,sourcezero);
    
    
    %% Plot sources on Anatomical MRI
    
    % First align sources with MRI
    cfg              = [];
    cfg.voxelcoord   = 'no';
    cfg.parameter    = 'pow';
    cfg.interpmethod = 'nearest';
    source_int  = ft_sourceinterpolate(cfg, source_diff, mri_realigned);
    
    %Now plot on top of anatomical
    
    source_int.mask = source_int.pow > 0.04; % anything above 0.04
    cfg               = [];
    cfg.method        = 'ortho';
    cfg.funparameter  = 'pow';
    cfg.maskparameter = 'mask';
    %cfg.location = [-42 -18 67];
    cfg.funcolormap = 'jet';
    %cfg.latency = [0.1 0.5];
    %ft_sourceplot(cfg, source_diff,mri_realigned);
    
    %% Save 
    %This saves in CTF coords. 
    cfg = [];
    cfg.filename = fullfile(outputDir,strcat('source_',subject,'_arabic'));
    cfg.filetype = 'nifti';
    cfg.parameter = 'pow';
    ft_sourcewrite(cfg,source_int);
    
    cfg=[];
    cfg.parameter = 'anatomy';
    cfg.filetype = 'nifti';
    cfg.filename = 'CTFStruct';
    cfg.datatype = 'double';
    %ft_volumewrite(cfg,mri_realigned);
    
    %Normalise into MNI coordinates for group analysis
    cfg = [];
    cfg.nonlinear = 'no';
    source_mni_norm = ft_volumenormalise(cfg,source_int);
    
    cfg = [];
    cfg.filename = fullfile(outputDir,strcat('source_',subject,'_arabic_mni'));
    cfg.filetype = 'nifti';
    cfg.parameter = 'pow';
    ft_sourcewrite(cfg,source_mni_norm);
    
    
    
   

end
