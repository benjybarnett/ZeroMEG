clear all;

%% SET WD
%cd Zero\scripts\analysis\

%% Paths
addpath(genpath('Utilities'))
addpath('D:\bbarnett\Documents\Zero\HMeta-d-master\Matlab')
addpath('D:\bbarnett\Documents\Zero\HMeta-d-master\CPC_metacog_tutorial\cpc_metacog_utils')
addpath('Decoding')
addpath('Decoding\plotting')
addpath('PreprocessingPipeline\')

addpath('D:\bbarnett\Documents\Zero\fieldtrip-master-MVPA\')
addpath('D:/bbarnett/Documents/ecobrain/MVPA-Light\startup')
addpath('D:/bbarnett/Documents/Zero/liblinear-master/')
addpath('D:/bbarnett/Documents/Zero/liblinear-master/matlab')
addpath('C:\Users\bbarnett\AppData\Local\JAGS\JAGS-3.4.0\x64\bin')

%% Set deaults
ft_defaults;
startup_MVPA_Light

%% Zero Project Analysis
subjects = {
    'sub01'
    'sub02'
    'sub03'
    'sub05'
    
    
    };



%% Behavioural
subjCurves = {};
d = {};
c = {};
md = {};
for subj = 1:length(subjects)
    subject = subjects{subj};
    
    cfg.root = 'D:\bbarnett\Documents\Zero\data\Raw';
    
    [d{subj},c{subj},md{subj},subjCurves{subj}] = BehaviourAnalysis(cfg,subject);
end
groupBehav(d,c,md,subjCurves);

%% Preprocessing
for subj = 1:length(subjects)
    subject = subjects{subj};
    disp(subject)
    
    %experimental tasks
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\PreprocData';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data\Raw';
    cfg.eventvalue = 1;
    cfg.prestim = 0.2;
    cfg.poststim = 2;
    cfg.saveName = 'data_preproc';
    cfg.wildcard = '*SF025*.ds';
    cfg.localizer = false;
    cfg.plot = true;
    PreprocessingTrialsPD_BOB(cfg,subject);
%{
    %localizer task
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\PreprocData';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data\Raw';
    cfg.eventvalue = 1;
    cfg.prestim = 0.2;
    cfg.poststim = 1;
    cfg.saveName = 'loc_data_preproc';
    cfg.wildcard = '*SF025*.ds';
    cfg.localizer = true;
    cfg.plot = true;
    PreprocessingTrialsPD_BOB(cfg,subject);
%}
end

%% Visual Artefact Rejection
for subj = 1:length(subjects)
    subject= subjects{subj};

    %experimental task
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\PreprocData';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
    cfg.stimOn = [0 0.1];
    cfg.dataName = 'data_preproc';
    cfg.saveName = 'data_VAR';
    cfg.localizer = false;
    PreprocessingVAR_BOB(cfg,subject);

%{
    %localizer task - can be more lenient on blink trials as stims on for
    %longer
    cfg.stimOn = [0 0.3]; 
    cfg.dataName = 'loc_data_preproc';
    cfg.saveName = 'loc_data_VAR';
    cfg.localizer = true;
    PreprocessingVAR_BOB(cfg,subject);
%}

end

%% Append Localizer to Main Task before ICA
for subj = 1:length(subjects)

    subject= subjects{subj};
    cfg = [];
    cfg.saveDir = 'D:\bbarnett\Documents\Zero\data\VARData';
    cfg.saveName = 'both_tasks_VAR.mat';
    appendTasks(cfg,subject);
    
end

%% Independent Components Analysis (ICA)
for subj = 1:length(subjects)
    subject= subjects{subj};
    
    %both tasks
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\VARData';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
    cfg.inputData = 'data_VAR';
    PreprocessingICA_BOB(cfg,subject)
    
end

%% Split Data Sets By Task
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg=[];
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
    Split_Tasks(cfg,subject);
end

%% Eyeball Preprocessed Data
for subj = 1:length(subjects)

    %eyeball detection task
    subject = subjects{subj};
    cfg = [];
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
    cfg.trials = 'all';
    cfg.channel = 'meg';
    cfg.file_name = 'det_data';
    cfg.layout = 'CTF275.lay';
    cfg.datatype = 'CleanData';
    EyeballData(cfg,subject);

    %eyeball numerical task
    cfg.file_name = 'num_data';
    EyeballData(cfg,subject);
%{
    %eyeball localiser
    cfg.file_name = 'loc_data';
    EyeballData(cfg,subject);
%}
end

%% %%%%%%%%%%%%%%%%%%%%% ANALYSIS %%%%%%%%%%%%%%%%%%%%% %%

%% RSA 
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\analysis';
    cfg.mRDM_file = 'dom_gen_rdm';
    cfg.num_predictors = 8;
    cfg.output_path = 'Analysis/MEG/RSA/Main';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    RSA(cfg,subject);
end

% Plot
models = {'shared_zero_rdm','dom_gen_rdm','no_sharing_rdm'};
colours = {'#ED217C','#1B998C','#62A6E3'};
figure('units','normalized','outerposition',[0 0 1 1])
for m = 1:length(models)
    model = models{m};
    cfg.linecolor = colours{m};
    cfg.shadecolor = cfg.linecolor;
    cfg.mRDM_file = model;
    cfg.ylim = [-0.4 0.8];
    plot_mean_RSA(cfg,subjects)
    hold on
end
legend({'','Shared Absence','','','', 'Domain General','','','','No Sharing'})
% Save Plot
outputDir = fullfile(cfg.root,cfg.output_path,'Group','RSA');
if ~exist(outputDir,'dir')
    mkdir(outputDir)
end
fig = gcf;
saveas(fig,fullfile(outputDir,'main_hypothesis.png'));

%% Multiclass Cross-Decoding Between Detection and Number
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.output_path = 'Analysis/MEG/Multiclass_Decoding';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.metric = {'acc','confusion'};
    cfg.output_prefix =  {'train_num_','train_det_'}; %must be number data first
    cfg.plot = false;
    cfg.channel = 'MEG';
    multiclass_cross(cfg,subject);
end
% Plot Group Average
cfg.accFile = 'multiclass_cross';
cfg.figName = cfg.accFile;
cfg.ylim = [0 0.5];
cfg.clim = [0.1 0.4];
cfg.decoding_type = 'cross';
plot_multiclass_temp(cfg,subjects);
% Correct and Plot Corrected Group Data
cfg.figName = strcat(cfg.accFile,'_corrected.png');
cfg.plot = true;
cfg.resultsFile = {'train_num_acc';'train_det_acc'}; %must be number data first
onesample_corrected(cfg,subjects);

%% Within Condition Multiclass Decoding
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.output_path = 'Analysis/MEG/Multiclass_Decoding';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.metric = {'acc'};
    cfg.output_prefix =  {'within_num_','within_det_'}; %must be number data first
    cfg.plot = false;
    cfg.channel = 'MEG';
    multiclass(cfg,subject);
end
% Plot Group Average
cfg.accFile = 'multiclass_within';
cfg.figName = cfg.accFile;
cfg.ylim = [0 0.5];
cfg.clim = [0.1 0.4];
cfg.decoding_type = 'within';
plot_multiclass_temp(cfg,subjects);
% Correct and Plot Corrected Group Data
cfg.figName = strcat(cfg.accFile,'_corrected.png');
cfg.plot = true;
cfg.resultsFile = {'within_num_acc';'within_det_acc'}; %must be number data first
onesample_corrected(cfg,subjects);

%% One vs. All Cross-Decoding
cfg  = [];
cfg.root = 'D:\bbarnett\Documents\Zero\data';
cfg.output_path = 'Analysis/MEG/One_v_All/Cross';
cfg.channel = 'MEG';
cfg.nMeanS = 7;
cfg.metric = 'acc';
cfg.plot = true;
cfg.figName = 'One_V_All_Cross';
[peak_samples,peak_times] = decodeOneVsAllCross(cfg,subjects);

%% One vs. All Within-Decoding
cfg=[];
cfg.root = 'D:\bbarnett\Documents\Zero\data';
cfg.output_path = 'Analysis/MEG/One_v_All/Within';
cfg.channel = 'MEG';
cfg.nMeanS = 7;
cfg.metric = 'acc';
cfg.plot = true;
cfg.peak_samples = peak_samples;
cfg.peak_times = peak_times;
cfg.figName = 'One_V_All_Within';
decodeOneVsAllWithin(cfg,subjects);

%% Representations of Zero RSA
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\analysis';
    cfg.mRDM_file = 'discrete_zero_rdm';
    cfg.num_predictors = 4;
    cfg.output_path = 'Analysis/MEG/RSA/Zero';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    RSA_Zero(cfg,subject);
end
% Plot
models = {'graded_zero_rdm','discrete_zero_rdm'};
colours = {'#C32F27','#4381C1'};
figure('units','normalized','outerposition',[0 0 1 1])
for m = 1:length(models)
    model = models{m};
    cfg.linecolor = colours{m};
    cfg.shadecolor = cfg.linecolor;
    cfg.mRDM_file = model;
    cfg.ylim = [-0.4 1];
    plot_mean_RSA(cfg,subjects)
    hold on
end
legend({'','Graded Zero','','','', 'Discrete Zero'})
% Save Plot
outputDir = fullfile(cfg.root,cfg.output_path,'Group');
fig = gcf;
saveas(fig,fullfile(outputDir,'zero_reps.png'));

%% Representation of Number: Confusion Matrix
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';

    cfg.output_path = 'Analysis/MEG/NumberDecoding/';
    cfg.outputName = 'number_confusion';
    cfg.timepoints = [0.2 0.6];
    cfg.channel = {'MEG'};
    cfg.nMeanS = 7;
    NumberConfusion(cfg,subject);
end
meanNumberConfusion(cfg,subjects);






















%% Control Analyses

%Detection
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\analysis';
    cfg.mRDM_file = 'det_control_rdm';
    cfg.num_predictors = 8;
    cfg.output_path = 'Analysis/MEG/RSA/Controls/Detection';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    RSA_DetControl(cfg,subject);
end
% Plot
colours = {'#E63946','#1B9AAA'};
figure('units','normalized','outerposition',[0 0 1 1])
model = 'det_control_rdm';
cfg.linecolor = colours{1};
cfg.shadecolor = cfg.linecolor;
cfg.mRDM_file = model;
cfg.ylim = [-0.4 1];
plot_mean_RSA(cfg,subjects)
hold on
% Numerical
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\analysis';
    cfg.mRDM_file = 'num_control_rdm';
    cfg.num_predictors = 8;
    cfg.output_path = 'Analysis/MEG/RSA/Controls/Number';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    RSA_NumControl(cfg,subject);
end
% Plot
model = 'num_control_rdm';
cfg.linecolor = colours{2};
cfg.shadecolor = cfg.linecolor;
cfg.mRDM_file = model;
cfg.ylim = [-0.4 1];
plot_mean_RSA(cfg,subjects)
legend({'','Detection Control','','','', 'Number Control'})
% Save Plot
outputDir = fullfile(cfg.root,'Analysis/MEG/RSA/Controls/');
fig = gcf;
saveas(fig,fullfile(outputDir,'Control_RSAs.png'));

% Multiclass cross decoding between faces and houses
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.output_path = 'Analysis/MEG/Multiclass_Decoding/PAS_Replication';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.metric = {'acc','confusion'};
    cfg.output_prefix =  {'train_house_','train_face_'}; %must be number data first
    cfg.plot = false;
    cfg.channel = 'MEG';
    multiclass_cross_det(cfg,subject);
end
% Plot Group Average
cfg.accFile = 'multiclass_cross';
cfg.figName = cfg.accFile;
cfg.ylim = [0 0.5];
cfg.clim = [0.1 0.4];
cfg.decoding_type = 'cross';
plot_multiclass_temp_det(cfg,subjects);
% Correct and Plot Corrected Group Data
cfg.figName = strcat(cfg.accFile,'_corrected.png');
cfg.plot = true;
cfg.resultsFile = {'train_house_acc';'train_face_acc'}; %must be number data first
onesample_corrected(cfg,subjects);

% House Vs. Face Decoding
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.task = 'detection';
    cfg.outputDir = 'Analysis/MEG/DiscrimDecoding/House_v_Face';
    cfg.outputName = 'binary_lda';
    cfg.conIdx = {'data.trialinfo(:,4) == 1 & data.trialinfo(:,5) ~= 2 '...
                    'data.trialinfo(:,4) == 2 & data.trialinfo(:,5) ~= 2 '}; 
    cfg.correct = true; %correct trials only
    cfg.nFold = 5;
    cfg.nMeanS = 7; %smooth over 0.02 seconds;
    cfg.gamma = 0.1;
    cfg.plot = false;
    cfg.title = '';
    diagDecode(cfg,subject);
end
%plot mean accuracy
cfg = [];
cfg.root =  'D:\bbarnett\Documents\Zero\data';
cfg.accDir = 'Analysis/MEG/DiscrimDecoding/House_v_Face';
cfg.accFile = 'binary_LDA.mat';
cfg.outputName = 'House_v_Face';
cfg.task = 'detection';
cfg.title = 'Mean Accuracy House v Face';
plot_mean_diag(cfg,subjects);

% Present Vs. Absent Binary Decoding
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.task = 'detection';
    cfg.outputDir = 'Analysis/MEG/BinaryDecoding/';
    cfg.outputName = 'Pres_Vs_Abs';
    cfg.conIdx = {'data.trialinfo(:,7) == 1 '...
                   'data.trialinfo(:,7) == 2 '}; %In face trials only
    cfg.correct = false; %correct trials only
    cfg.nFold = 5;
    cfg.nMeanS = 7; %smooth over 0.02 seconds;
    cfg.gamma = 0.1;
    cfg.plot = false;
    cfg.title = '';
    diagDecode(cfg,subject);
    
end
%plot mean accuracy
cfg = [];
cfg.root =  'D:\bbarnett\Documents\Zero\data';
cfg.accDir = 'Analysis/MEG/BinaryDecoding';
cfg.accFile = 'Pres_Vs_Abs.mat';
cfg.outputName = 'pres_v_abs';
cfg.task = 'detection';
cfg.title = 'Mean Accuracy Present v Absent ';
plot_mean_diag(cfg,subjects);
