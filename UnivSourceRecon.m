
outputDir = fullfile('Univariate\dots');
if ~isfolder(outputDir);mkdir(outputDir);end

progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};
    %Create Forward Model
    disp(subject)

    cfg = [];
    cfg.rawDir =  'data\Raw';
    cfg.trim = false;
    [headmodel,sourcemodel,grad,pos,template_source] = ForwardModel(cfg,subject);

    
    load(fullfile('data\CleanData\',subject,'\dot_trials.mat'));
    cfg = [];
    cfg.channel = 'meg';
    cfg.latency = [0.1 0.45]; %select latency of interest
    meg_data = ft_selectdata(cfg,dot_trials);
    clear dot_trials
      
    meg_data.grad = grad; 
    cfg = [];
    cfg.trials = meg_data.trialinfo(:,5) == 0 & meg_data.trialinfo(:,4) == 1;
    datazero = ft_selectdata(cfg,meg_data);
    cfg.trials = meg_data.trialinfo(:,5) > 0 & meg_data.trialinfo(:,4) == 1;
    datanotzero = ft_selectdata(cfg,meg_data);
    
    % Compute Covariance Matrix
    cfg = [];
    cfg.covariance = 'yes';
    avg = ft_timelockanalysis(cfg,meg_data);
    
    %cfg.keeptrials = 'yes';
    avgzero = ft_timelockanalysis(cfg,datazero);
    avgnotzero = ft_timelockanalysis(cfg,datanotzero);
    
    %Calculate spatial filter for each voxel over all data
    cfg = [];
    cfg.method = 'lcmv';
    cfg.sourcemodel = sourcemodel;
    cfg.headmodel = headmodel;
    cfg.lcmv.keepfilter = 'yes';
    cfg.lcmv.lambda = '5%';
    cfg.lcmv.fixedori = 'yes';
    cfg.channel = {'MEG'};
    cfg.senstype = 'MEG';
    sourceavg = ft_sourceanalysis(cfg, avg);
    %dot_filters{subj} = sourceavg.avg.filter;

    %Now apply this filter to zero and nonzero data separately
    cfg = [];
    cfg.method = 'lcmv';
    cfg.sourcemodel = sourcemodel;
    cfg.sourcemodel.filter = sourceavg.avg.filter;
    cfg.headmodel = headmodel;
    cfg.senstype = 'MEG';
    grandavgZero{subj} = ft_sourceanalysis(cfg, avgzero);
    grandavgNotZero{subj} = ft_sourceanalysis(cfg, avgnotzero);
    

    grandavgZero{subj}.pos = pos;
    grandavgNotZero{subj}.pos = pos;
   
    
    progressbar(subj/length(subjects));
end
save('dot_grandavgZero.mat','grandavgZero')
save('dot_grandavgNotZero.mat','grandavgNotZero')

for subj = 1:length(subjects)
    sourcezero = grandavgZero{subj};
    sourcenotzero = grandavgNotZero{subj};

    
    szero = get_source_pow([],sourcezero,[sourcezero.time(1),sourcezero.time(end)]);
    snotzero = get_source_pow([],sourcenotzero,[sourcenotzero.time(1),sourcenotzero.time(end)]);


    newgrandavgZero{subj} = szero;
    newgrandavgNotZero{subj} = snotzero;

end

%Group Stats
cfg=[];
cfg.dim         = grandavgZero{1}.dim;
cfg.method      = 'montecarlo';
cfg.statistic   = 'ft_statfun_depsamplesT';
cfg.parameter   = 'pow';
cfg.correctm    = 'cluster';
cfg.computecritval = 'yes';
cfg.numrandomization = 1000;
cfg.clusteralpha = 0.05;
cfg.alpha       = 0.05; 
cfg.tail        = 1;


nsubj=numel(grandavgZero);
cfg.design(1,:) = [1:nsubj 1:nsubj];
cfg.design(2,:) = [ones(1,nsubj)*1 ones(1,nsubj)*2];
cfg.uvar        = 1; % row of design matrix that contains unit variable (in this case: subjects)
cfg.ivar        = 2; % row of design matrix that contains independent variable (the conditions)


stat = ft_sourcestatistics(cfg,grandavgZero{:}, grandavgNotZero{:});

% Load MRI MNI template
mri = ft_read_mri('fieldtrip-master-MVPA\template\anatomy\single_subj_T1.nii');
stat.mask(isnan(stat.mask),:) = 0;
stat.mask = logical(stat.mask);

cfg = [];
cfg.parameter = 'all';
statplot = ft_sourceinterpolate(cfg,stat,mri);

cfg = [];
cfg.method = 'surface';
cfg.funparameter = 'stat';
cfg.maskparameter = 'mask';
%cfg.location = stat.pos(maxtindx,:);
cfg.funcolormap = 'jet';
ft_sourceplot(cfg,statplot);

cfg.filename = 'dot_zero_contrast_sig_mask.nii';
cfg.filetype = 'nifti';
cfg.parameter = 'mask';
ft_sourcewrite(cfg,statplot);
cfg.filename = 'dot_zero_contrast_t.nii';
cfg.parameter = 'stat';
ft_sourcewrite(cfg,statplot);


save(fullfile(outputDir,'grandavgZero'),"grandavgZero")
save(fullfile(outputDir,'grandavgNotZero'),"grandavgNotZero")

clearvars -except subjects mri statplot stat 

%% Arabic
outputDir = fullfile('data\Analysis\MEG\Source\Univariate\arabic');
if ~isfolder(outputDir);mkdir(outputDir);end

progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};
    %Create Forward Model
    disp(subject)

    cfg = [];
    cfg.rawDir =  'data\Raw';
    cfg.trim = false;
    [headmodel,sourcemodel,grad,pos,template_source] = ForwardModel(cfg,subject);

     outputDir = fullfile('data\Analysis\Source\',subject);
    if ~isfolder(outputDir);mkdir(outputDir);end

    load(fullfile('data\CleanData\',subject,'\arabic_trials.mat'));
    cfg = [];
    cfg.channel = 'meg';
    cfg.latency = [0.1 0.45]; %select latency of interest
    meg_data = ft_selectdata(cfg,arabic_trials);
    clear arabic_trials
      
    meg_data.grad = grad; 
    cfg = [];
    cfg.trials = meg_data.trialinfo(:,4) == 0 ;
    datazero = ft_selectdata(cfg,meg_data);
    cfg.trials = meg_data.trialinfo(:,4) > 0 ;
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
    cfg.sourcemodel = sourcemodel;
    cfg.headmodel = headmodel;
    cfg.lcmv.keepfilter = 'yes';
    %cfg.lcmv.fixedori = 'yes';
    cfg.lcmv.lambda = '5%';
    cfg.channel = {'MEG'};
    cfg.senstype = 'MEG';
    sourceavg = ft_sourceanalysis(cfg, avg);
    %arabic_filters{subj} = sourceavg.avg.filter;
    
    %Now apply this filter to zero and five data separately
    cfg = [];
    cfg.method = 'lcmv';
    cfg.sourcemodel = sourcemodel;
    cfg.sourcemodel.filter = sourceavg.avg.filter;
    cfg.headmodel = headmodel;
    cfg.senstype = 'MEG';
    arabic_grandavgZero{subj} = ft_sourceanalysis(cfg, avgzero);
    arabic_grandavgNotZero{subj} = ft_sourceanalysis(cfg, avgnotzero);

    arabic_grandavgZero{subj}.pos = pos;
    arabic_grandavgNotZero{subj}.pos = pos;
   
    
    progressbar(subj/length(subjects));
end

% Save
save('arabic_grandavgZero.mat','arabic_grandavgZero')
save('arabic_grandavgNotZero.mat','arabic_grandavgNotZero')

for subj = 1:length(subjects)
    sourcezero = arabic_grandavgZero{subj};
    sourcenotzero = arabic_grandavgNotZero{subj};

    
    szero = get_source_pow([],sourcezero,[sourcezero.time(1),sourcezero.time(end)]);
    snotzero = get_source_pow([],sourcenotzero,[sourcenotzero.time(1),sourcenotzero.time(end)]);

    arabic_newgrandavgZero{subj} = szero;
    arabic_newgrandavgNotZero{subj} = snotzero;

end

%Group Stats
cfg=[];
cfg.dim         = arabic_grandavgZero{1}.dim;
cfg.method      = 'montecarlo';
cfg.statistic   = 'ft_statfun_depsamplesT';
cfg.parameter   = 'pow';
cfg.correctm    = 'cluster';
cfg.computecritval = 'yes';
cfg.numrandomization = 1000;
cfg.clusteralpha = 0.05;
cfg.alpha       = 0.05; 
cfg.tail        = 1;


nsubj=numel(arabic_grandavgZero);
cfg.design(1,:) = [1:nsubj 1:nsubj];
cfg.design(2,:) = [ones(1,nsubj)*1 ones(1,nsubj)*2];
cfg.uvar        = 1; % row of design matrix that contains unit variable (in this case: subjects)
cfg.ivar        = 2; % row of design matrix that contains independent variable (the conditions)


arabic_stat = ft_sourcestatistics(cfg,arabic_newgrandavgZero{:}, arabic_newgrandavgNotZero{:});
%arabic_stat = rmfield(arabic_stat,"negclusters"); % Remove empty field or error in ft_sourceinterpolate

arabic_stat.mask(isnan(arabic_stat.mask),:) = 0;
arabic_stat.mask = logical(arabic_stat.mask);

cfg = [];
cfg.parameter = 'all';
ar_statplot = ft_sourceinterpolate(cfg,arabic_stat,mri);

cfg = [];
cfg.method = 'surface';
cfg.funparameter = 'stat';
cfg.maskparameter = 'mask';
cfg.funcolormap = 'jet';
ft_sourceplot(cfg,ar_statplot);

cfg.filename = 'arabic_zero_contrast_t.nii';
cfg.filetype = 'nifti';
cfg.parameter = 'stat';
ft_sourcewrite(cfg,ar_statplot);
cfg.filename = 'arabic_zero_sig_mask.nii';
cfg.parameter = 'mask';
ft_sourcewrite(cfg,ar_statplot);

%% Conjunction
%Remove NaNs from mask
stat.mask(isnan(stat.mask),:) = 0;
arabic_stat.mask(isnan(arabic_stat.mask)) = 0;

conj = ft_conjunctionanalysis([],arabic_stat,stat);

cfg = [];
cfg.parameter = 'all';
conj_statplot = ft_sourceinterpolate(cfg,conj,mri);

cfg = [];
cfg.method = 'surface';
cfg.funparameter = 'mask';
cfg.maskparameter = 'mask';
cfg.funcolormap = 'jet';
ft_sourceplot(cfg,conj_statplot,mri);

save('conj','conj')

%% Save For Display
cfg.filename = 'conjunction.nii';
cfg.filetype = 'nifti';
cfg.parameter = 'mask';
ft_sourcewrite(cfg,conj_statplot);
