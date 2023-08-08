clear all;
set(0,'DefaultFigureWindowStyle','docked');
%% SET WD
cd D:\bbarnett\Documents\Zero\scripts\ZeroMEG\analysis

%% Paths
addpath(genpath('Utilities'))
addpath('D:\bbarnett\Documents\Zero\HMeta-d-master\Matlab')
addpath('D:\bbarnett\Documents\Zero\HMeta-d-master\CPC_metacog_tutorial\cpc_metacog_utils')
addpath('Decoding')
addpath('SourceRecon')
addpath('Decoding\plotting')
addpath('PreprocessingPipeline\')
addpath(genpath('warping_scripts'))


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
    %'sub012' %removed for movement being huge (between 16 - 28mm consistnetly)
    %'sub013' %removed for sleeping at 49% accuracy in arabic task
    'sub014'
    %'sub015' %collected no data as he couldn't see with new contact lenses
    'sub016'
    'sub017'
    'sub018'
    'sub019'
    'sub020'
    'sub021'
    'sub022'
    'sub023'
    'sub024'
    }; 


%% Behavioural
subjCurves = {};
meanRTs = {};
for subj = 1:length(subjects)
    subject = subjects{subj};
    
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\Raw';
    cfg.plot = false;
    [subjCurves{subj},meanRTs{subj}] = BehaviourAnalysis(cfg,subject);
end
groupBehav(subjCurves,meanRTs);

%% Preprocessing
for subj = 1:length(subjects)
    subject = subjects{subj};
    disp(subject)
    
    %experimental tasks
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\PreprocData';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data\Raw';
    cfg.dotEventValue = 3;
    cfg.arabicEventValue = 1;
    cfg.prestimArabic = 0.5;
    cfg.poststimArabic = 4;
    cfg.prestimDot = 0.2;
    cfg.poststimDot = 2.5;
    cfg.saveName = 'data_preproc';
    cfg.wildcard = '*SF025*.ds';
    cfg.plot = true;
    PreprocessingTrialsPD_BOB(cfg,subject);

end

%% Visual Artefact Rejection
for subj = 1:length(subjects)
    subject= subjects{subj};

    %arabic task
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\PreprocData';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
    cfg.stimOn = [0 0]; %dont look for blinks as too long a trial, one blink doesnt ruin whole trial
    cfg.dataName = 'arabic_data_preproc';
    cfg.saveName = 'arabic_data_VAR';
    cfg.blinks = 0;
    PreprocessingVAR_BOB(cfg,subject);
   
    %dot
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\PreprocData';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
    cfg.stimOn = [0 0.25];
    cfg.dataName = 'dot_data_preproc';
    cfg.saveName = 'dot_data_VAR';
    cfg.blinks = 0;
    PreprocessingVAR_BOB(cfg,subject);
    
    
end


%% Independent Components Analysis (ICA)
for subj = 1:length(subjects)
    subject= subjects{subj};
    
    %arabic
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\VARData';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
    cfg.inputData = 'arabic_data_VAR';
    cfg.compOutput = 'arabic_comp';
    cfg.outputData = 'arabic_data';
    PreprocessingICA_BOB(cfg,subject)
    
    %dot
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\VARData'; 
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
    cfg.inputData = 'dot_data_VAR'; 
    cfg.compOutput = 'dot_comp';
    cfg.outputData = 'dot_data';
    PreprocessingICA_BOB(cfg,subject)
    
    
end


%% Split into smaller epochs
for subj = 1:length(subjects)
    subject = subjects{subj};
    disp(subject)
    

    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data\CleanData';
    cfg.arabicSaveName = 'arabic_trials.mat';
    cfg.dotSaveName = 'dot_trials.mat';
    cfg.arabic_poststim = 0.8;
    cfg.arabic_prestim = 0.1;
    cfg.dot_poststim = 0.8;
    cfg.dot_prestim = 0.2;
    EpochTrialsAlternative(cfg,subject);
    EpochTrials(cfg,subject);

end

%% Eyeball Preprocessed Data
for subj = 1:length(subjects)

    %eyeball arabic task
    subject = subjects{subj};
    cfg = [];
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
    cfg.trials = 'all';
    cfg.channel = 'meg';
    cfg.file_name = 'arabic_trials';
    cfg.layout = 'CTF275.lay';
    cfg.datatype = 'CleanData';
    EyeballData(cfg,subject);

    %eyeball numerical task
    cfg.file_name = 'dot_trials';
    EyeballData(cfg,subject);
end

%% SANITY CHECKS %%

%% Representations of Zero RSA
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\ZeroMEG\analysis';
    cfg.mRDM_file = 'discrete_zero_rdm';
    cfg.num_predictors = 6;
    cfg.output_path = 'Analysis/MEG/RSA/Zero';
    cfg.dot_output_folder = 'dots';
    cfg.arabic_output_folder = 'arabic';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    cfg.plot = false;
    RSA_Zero(cfg,subject);
end
% Plot
models = {'graded_zero_rdm','discrete_zero_rdm'};
colours = {'#C32F27',"#0496FF"};
figure('units','normalized','outerposition',[0 0 1 1])
for m = 1:length(models)
    model = models{m};
    cfg.linecolor = colours;
    cfg.shadecolor = cfg.linecolor;
    cfg.mRDM_file = model;
    cfg.ylim = [-0.4 1];
    plot_mean_RSA(cfg,subjects)
    hold on
end


%% Within Condition Multiclass Decoding
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.output_path = 'Analysis/MEG/Multiclass_Decoding/OverTime';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.metric = {'acc','conf'};
    cfg.output_prefix =  {'within_arabic_','within_dot_'}; %must be number data first
    cfg.plot = true;
    cfg.channel = 'MEG';
    multiclass(cfg,subject);
    
end
% Plot Group Average
cfg.accFile = 'multiclass_within';
cfg.figName = cfg.accFile;
cfg.ylim = [0 0.7];
cfg.clim = [0.0 0.7];
cfg.decoding_type = 'within';
plot_multiclass_temp(cfg,subjects);

%% Cross Condition Multiclass Decoding
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.output_path = 'Analysis/MEG/Multiclass_Decoding/OverTime';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.metric = {'acc','conf'};
    cfg.output_prefix =  {'cross_arabic_','cross_dot_'}; %must be number data first
    cfg.plot = false;
    cfg.channel = 'MEG';
    cfg.sysRemove =true;
    multiclass_cross(cfg,subject);
    
end
% Plot Group Average
cfg.accFile = 'multiclass_cross';
cfg.figName = cfg.accFile;
cfg.ylim = [0.1 0.3];
cfg.clim = [0.1 0.3];
cfg.decoding_type = 'cross';
plot_multiclass_temp(cfg,subjects);

%% Within Condition Zero V All Decoding
progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.output_path = 'Analysis/MEG/Zero_Decoding/OverTime';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.metric = {'acc','conf'};
    cfg.output_prefix =  {'within_arabic_','within_dot_'}; %must be number data first
    cfg.plot = false;
    cfg.channel = 'MEG';
    cfg.sysRemove = true;
    decodeZeroVAll(cfg,subject);
    progressbar(subj/length(subjects));
end
% Plot Group Average
cfg.accFile = 'zero_vs_all';
cfg.figName = cfg.accFile;
cfg.ylim = [0.4 0.9];
cfg.clim = [0.4 0.9];
cfg.decoding_type = 'within';
plot_multiclass_temp(cfg,subjects);


%% Cross Condition Zero V All Decoding
progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.output_path = 'Analysis/MEG/Zero_Decoding/OverTime';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.metric = {'acc','conf'};
    cfg.output_prefix =  {'train_arabic_','train_dot_'}; %must be number data first
    cfg.plot = false;
    cfg.channel = 'MEG';
    cfg.sysRemove = true;
    decodeZeroVAll_cross(cfg,subject);
    progressbar(subj/length(subjects));  
end
% Plot Group Average
cfg.accFile = 'zero_vs_all';
cfg.figName = cfg.accFile;
cfg.ylim = [0.4 0.7];
cfg.clim = [0.4 0.7];
cfg.decoding_type = 'cross';
plot_multiclass_temp(cfg,subjects);

%% Cross Condition RSA
progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\ZeroMEG\analysis';
    cfg.mRDM_file = 'shared_numbers_discrete_rdm';
    cfg.num_predictors = 12;
    cfg.output_path = 'Analysis/MEG/RSA/CrossModality';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    cfg.plot = false;

    RSA_Cross(cfg,subject);
    progressbar(subj/length(subjects));

end
% Plot
models = {'shared_numbers_rdm','shared_numbers_discrete_rdm'};
linecolor = {'magenta','cyan'};
figure;
for model = 1:length(models)
    cfg.linecolor = linecolor{model};
    cfg.shadecolor = linecolor{model};
    cfg.mRDM_file = models{model};
    cfg.ylim = [-0.15 0.15];
    cfg.task = 'CrossModality';
    cfg.title = 'Domain General Numerosity With/Without Distance Effect';
    plot_mean_single_RSA(cfg,subjects);
    hold on
end
legend('','With Distance Effect','','','','Without Distance Effect')


%% Representation of Number: Confusion Matrix
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';

    cfg.output_path = 'Analysis/MEG/Multiclass_Decoding/TimeAveraged';
    cfg.outputName = 'number_confusion';
    cfg.timepoints = [0.35 0.6];
    cfg.channel = {'MEG'};
    NumberConfusion(cfg,subject);
end
meanNumberConfusion(cfg,subjects);

%Dots Control
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\ZeroMEG\analysis';
    cfg.mRDM_file = 'dot_control_rdm';
    cfg.num_predictors = 6;
    cfg.output_path = 'Analysis/MEG/RSA/Controls/Dots';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    RSA_DotControl(cfg,subject);
end
% Plot
colours = {'#E63946'};
figure('units','normalized','outerposition',[0 0 1 1])
model = 'dot_control_rdm';
cfg.linecolor = colours;
cfg.shadecolor = cfg.linecolor;
cfg.mRDM_file = model;
cfg.task = 'dots';
cfg.ylim = [-0.4 1];
cfg.title = 'Dot Stim-Set Control';
plot_mean_single_RSA(cfg,subjects)

% Arabic Control
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\ZeroMEG\analysis';
    cfg.mRDM_file = 'arabic_control_rdm';
    cfg.num_predictors = 6;
    cfg.output_path = 'Analysis/MEG/RSA/Controls/Arabic';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    RSA_ArabicControl(cfg,subject);
end
% Plot
model = 'arabic_control_rdm';
cfg.linecolor = {'blue'};
cfg.shadecolor = cfg.linecolor;
cfg.mRDM_file = model;
cfg.ylim = [-0.4 1];
cfg.task = 'arabic';
cfg.title = 'Arabic Colour Control';
plot_mean_single_RSA(cfg,subjects)




%% END SANITY CHECKS

%Source ROI Decoding
tic;
progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};

    disp(subject);
    
    %Dots
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.rawDir =  'D:\bbarnett\Documents\Zero\data\Raw';
    cfg.vChanOutDir = 'Analysis\MEG\Source\virtualchannels\dots';
    cfg.roiLabelIdxs = {'Cingulum_Ant_L', 'Cingulum_Ant_R',  'Rectus_L', 'Rectus_R', 'Frontal_Sup_L'	'Frontal_Sup_R'	'Frontal_Sup_Orb_L'	'Frontal_Sup_Orb_R'	'Frontal_Mid_L'	'Frontal_Mid_R'	'Frontal_Mid_Orb_L'	'Frontal_Mid_Orb_R'	'Frontal_Inf_Oper_L'	'Frontal_Inf_Oper_R'	'Frontal_Inf_Tri_L'	'Frontal_Inf_Tri_R'	'Frontal_Inf_Orb_L'	'Frontal_Inf_Orb_R'	'Frontal_Sup_Medial_L'	'Frontal_Sup_Medial_R'	'Frontal_Med_Orb_L'	'Frontal_Med_Orb_R'};
    cfg.roi_name = 'frontal';
    cfg.tSmooth = 7;
    cfg.group_size = 5;
    cfg.pca =false;
    cfg.outdir = 'Analysis\MEG\Source\Decoding\dots';
    cfg.sensor_data = 'dot_trials.mat';
    cfg.metric = {'accuracy' 'confusion'};
    cfg.timepoints = [0.35 0.6];
    cfg.condition_trls = {'meg_data.trialinfo(:,5) == 0 & meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,8) ~= 0'
                            'meg_data.trialinfo(:,5) == 1 & meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,8) ~= 0'
                            'meg_data.trialinfo(:,5) == 2 & meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,8) ~= 0'
                            'meg_data.trialinfo(:,5) == 3 & meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,8) ~= 0'
                            'meg_data.trialinfo(:,5) == 4 & meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,8) ~= 0'
                            'meg_data.trialinfo(:,5) == 5 & meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,8) ~= 0'}; %sample image, and only images with a response
    SourceDecode(cfg,subject); %frontal decoding

    cfg.roiLabelIdxs = {'Parietal_Sup_L'	'Parietal_Sup_R'	'Parietal_Inf_L'	'Parietal_Inf_R' 'SupraMarginal_L'	'SupraMarginal_R'	'Angular_L'	'Angular_R' 'Precuneus_L' 'Precuneus_R'};
    cfg.roi_name = 'parietal';
    SourceDecode(cfg,subject); %parietal decoding

    %Arabic
    cfg.vChanOutDir = 'Analysis\MEG\Source\virtualchannels\arabic';
    cfg.roiLabelIdxs = {'Cingulum_Ant_L', 'Cingulum_Ant_R',  'Rectus_L', 'Rectus_R', 'Frontal_Sup_L'	'Frontal_Sup_R'	'Frontal_Sup_Orb_L'	'Frontal_Sup_Orb_R'	'Frontal_Mid_L'	'Frontal_Mid_R'	'Frontal_Mid_Orb_L'	'Frontal_Mid_Orb_R'	'Frontal_Inf_Oper_L'	'Frontal_Inf_Oper_R'	'Frontal_Inf_Tri_L'	'Frontal_Inf_Tri_R'	'Frontal_Inf_Orb_L'	'Frontal_Inf_Orb_R'	'Frontal_Sup_Medial_L'	'Frontal_Sup_Medial_R'	'Frontal_Med_Orb_L'	'Frontal_Med_Orb_R'};
    cfg.roi_name = 'frontal';
    cfg.outdir = 'Analysis\MEG\Source\Decoding\arabic';
    cfg.sensor_data = 'arabic_trials.mat';
    cfg.group_size = 5;
    cfg.timepoints = [0.35 0.6];
    cfg.condition_trls = {'meg_data.trialinfo(:,4) == 0 & meg_data.trialinfo(:,6) ~= 0'
                            'meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,6) ~= 0'
                            'meg_data.trialinfo(:,4) == 2 & meg_data.trialinfo(:,6) ~= 0'
                            'meg_data.trialinfo(:,4) == 3 & meg_data.trialinfo(:,6) ~= 0'
                            'meg_data.trialinfo(:,4) == 4 & meg_data.trialinfo(:,6) ~= 0'
                            'meg_data.trialinfo(:,4) == 5 & meg_data.trialinfo(:,6) ~= 0'}; 
    SourceDecode(cfg,subject); %frontal decoding

    cfg.roiLabelIdxs = {'Parietal_Sup_L'	'Parietal_Sup_R'	'Parietal_Inf_L'	'Parietal_Inf_R' 'SupraMarginal_L'	'SupraMarginal_R'	'Angular_L'	'Angular_R' 'Precuneus_L' 'Precuneus_R'};
    cfg.roi_name = 'parietal';
    SourceDecode(cfg,subject); %parietal decoding

    progressbar(subj/length(subjects));
    
end
toc;

%Source ROI Cross-Decoding
tic;
progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};

    disp(subject);
    
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.rawDir =  'D:\bbarnett\Documents\Zero\data\Raw';
    cfg.vChanOutDir = 'Analysis\MEG\Source\virtualchannels\';
    cfg.roi_name = 'frontal';
    cfg.tSmooth = 7;
    cfg.group_size = 5;
    cfg.pca =false;
    cfg.outdir = 'Analysis\MEG\Source\Decoding\Cross\';
    cfg.metric = {'accuracy' 'confusion'};
    cfg.timepoints = [0.35 0.6];
    SourceCrossDecode(cfg,subject); %frontal decoding

    cfg.roi_name = 'parietal';
    SourceCrossDecode(cfg,subject); %parietal decoding


    progressbar(subj/length(subjects));
    
end
toc;


%% SOURCE RSA ZERO
tic;
progressbar;
fro_pc_dot = [];
par_pc_dot = [];
fro_pc_arab = [];
par_pc_arab = [];
for subj = 1:length(subjects)
    subject = subjects{subj};

    disp(subject);
    
    %Dots
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.rawDir =  'D:\bbarnett\Documents\Zero\data\Raw';
    cfg.vChanOutDir = 'Analysis\MEG\Source\virtualchannels\dots';
    cfg.roiLabelIdxs = {'Cingulum_Ant_L', 'Cingulum_Ant_R',  'Rectus_L', 'Rectus_R', 'Frontal_Sup_L'	'Frontal_Sup_R'	'Frontal_Sup_Orb_L'	'Frontal_Sup_Orb_R'	'Frontal_Mid_L'	'Frontal_Mid_R'	'Frontal_Mid_Orb_L'	'Frontal_Mid_Orb_R'	'Frontal_Inf_Oper_L'	'Frontal_Inf_Oper_R'	'Frontal_Inf_Tri_L'	'Frontal_Inf_Tri_R'	'Frontal_Inf_Orb_L'	'Frontal_Inf_Orb_R'	'Frontal_Sup_Medial_L'	'Frontal_Sup_Medial_R'	'Frontal_Med_Orb_L'	'Frontal_Med_Orb_R'};
    cfg.roi_name = 'frontal';
    cfg.group_size = 5;
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\ZeroMEG\analysis';
    cfg.mRDM_file = 'discrete_zero_rdm';
    cfg.outdir = 'Analysis\MEG\Source\RSA\dots';
    cfg.sensor_data = 'dot_trials.mat';
    cfg.num_predictors = 6;
    cfg.pca = false;
    cfg.condition_trls = {'meg_data.trialinfo(:,5) == 0 & meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,8) ~= 0'
                            'meg_data.trialinfo(:,5) == 1 & meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,8) ~= 0'
                            'meg_data.trialinfo(:,5) == 2 & meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,8) ~= 0'
                            'meg_data.trialinfo(:,5) == 3 & meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,8) ~= 0'
                            'meg_data.trialinfo(:,5) == 4 & meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,8) ~= 0'
                            'meg_data.trialinfo(:,5) == 5 & meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,8) ~= 0'}; %sample image, and only images with a response
    pc = SourceRSA_Zero(cfg,subject); %frontal decoding
    fro_pc_dot = [fro_pc_dot pc];
    cfg.roiLabelIdxs = {'Parietal_Sup_L'	'Parietal_Sup_R'	'Parietal_Inf_L'	'Parietal_Inf_R' 'SupraMarginal_L'	'SupraMarginal_R'	'Angular_L'	'Angular_R' 'Precuneus_L' 'Precuneus_R'};
    cfg.roi_name = 'parietal';
    pc = SourceRSA_Zero(cfg,subject); %parietal decoding
    par_pc_dot = [par_pc_dot pc];

    %Arabic
    cfg.vChanOutDir = 'Analysis\MEG\Source\virtualchannels\arabic';
    cfg.roiLabelIdxs = {'Cingulum_Ant_L', 'Cingulum_Ant_R',  'Rectus_L', 'Rectus_R', 'Frontal_Sup_L'	'Frontal_Sup_R'	'Frontal_Sup_Orb_L'	'Frontal_Sup_Orb_R'	'Frontal_Mid_L'	'Frontal_Mid_R'	'Frontal_Mid_Orb_L'	'Frontal_Mid_Orb_R'	'Frontal_Inf_Oper_L'	'Frontal_Inf_Oper_R'	'Frontal_Inf_Tri_L'	'Frontal_Inf_Tri_R'	'Frontal_Inf_Orb_L'	'Frontal_Inf_Orb_R'	'Frontal_Sup_Medial_L'	'Frontal_Sup_Medial_R'	'Frontal_Med_Orb_L'	'Frontal_Med_Orb_R'};
    cfg.roi_name = 'frontal';
    cfg.outdir = 'Analysis\MEG\Source\RSA\arabic';
    cfg.sensor_data = 'arabic_trials.mat';
    cfg.group_size = 5;
    cfg.condition_trls = {'meg_data.trialinfo(:,4) == 0 & meg_data.trialinfo(:,6) ~= 0'
                            'meg_data.trialinfo(:,4) == 1 & meg_data.trialinfo(:,6) ~= 0'
                            'meg_data.trialinfo(:,4) == 2 & meg_data.trialinfo(:,6) ~= 0'
                            'meg_data.trialinfo(:,4) == 3 & meg_data.trialinfo(:,6) ~= 0'
                            'meg_data.trialinfo(:,4) == 4 & meg_data.trialinfo(:,6) ~= 0'
                            'meg_data.trialinfo(:,4) == 5 & meg_data.trialinfo(:,6) ~= 0'}; 
    pc = SourceRSA_Zero(cfg,subject); %frontal decoding
    fro_pc_arab = [fro_pc_arab pc];

    cfg.roiLabelIdxs = {'Parietal_Sup_L'	'Parietal_Sup_R'	'Parietal_Inf_L'	'Parietal_Inf_R' 'SupraMarginal_L'	'SupraMarginal_R'	'Angular_L'	'Angular_R' 'Precuneus_L' 'Precuneus_R'};
    cfg.roi_name = 'parietal';
    pc = SourceRSA_Zero(cfg,subject); %parietal decoding
    par_pc_arab = [par_pc_arab pc];

    progressbar(subj/length(subjects));
    
end
toc;
% Plot
models = {'graded_zero_rdm','discrete_zero_rdm'};
colours = {'#C32F27',"#0496FF"};
figure('units','normalized','outerposition',[0 0 1 1])
regions = {'parietal','frontal'};
for j = 1:length(regions)
    figure;
    for m = 1:length(models)
        
        model = models{m};
        cfg.linecolor = colours;
        cfg.shadecolor = cfg.linecolor;
        cfg.mRDM_file = model;
        cfg.ylim = [-0.3 0.8];
        if m > 1
            cfg.dashed = true;
        else
            cfg.dashed = false;
        end

        cfg.output_path =  'Analysis\MEG\Source\RSA\';
        cfg.region = regions{j};
        plot_mean_RSA_source(cfg,subjects)
        hold on
    end
end
%% %%%%%%%%%%%%%%%%%%%%% ANALYSIS %%%%%%%%%%%%%%%%%%%%% %;%


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

%% Multiclass Cross-Decoding Between Arabic and Dots
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.output_path = 'Analysis/MEG/Multiclass_Decoding/OverTime';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.metric = {'acc'};
    cfg.output_prefix =  {'train_arabic_','train_dot_'}; %must be number data first
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
    cfg.output_path = 'Analysis/MEG/Multiclass_Decoding/OverTime';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.metric = {'acc','conf'};
    cfg.output_prefix =  {'within_arabic_','within_dot_'}; %must be number data first
    cfg.plot = true;
    cfg.channel = 'MEG';
    multiclass(cfg,subject);
    
end
% Plot Group Average
cfg.accFile = 'multiclass_within';
cfg.figName = cfg.accFile;
cfg.ylim = [0 0.5];
cfg.clim = [0.0 0.5];
cfg.decoding_type = 'within';
plot_multiclass_temp(cfg,subjects);
% Correct and Plot Corrected Group Data
cfg.figName = strcat(cfg.accFile,'_corrected.png');
cfg.plot = true;
cfg.resultsFile = {'within_arabic_acc';'within_dot_acc'}; %must be number data first
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
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\ZeroMEG\analysis';
    cfg.mRDM_file = 'graded_zero_rdm';
    cfg.num_predictors = 6;
    cfg.output_path = 'Analysis/MEG/RSA/Zero';
    cfg.dot_output_folder = 'dots';
    cfg.arabic_output_folder = 'arabic';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    cfg.plot = true;
    RSA_Zero(cfg,subject);
end
% Plot
models = {'graded_zero_rdm'};
colours = {'#C32F27',"#0496FF"};
figure('units','normalized','outerposition',[0 0 1 1])
for m = 1:length(models)
    model = models{m};
    cfg.linecolor = colours;
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

    cfg.output_path = 'Analysis/MEG/Multiclass_Decoding/TimeAveraged';
    cfg.outputName = 'number_confusion';
    cfg.timepoints = [0.1 0.3];
    cfg.channel = {'MEG'};
    NumberConfusion(cfg,subject);
end
meanNumberConfusion(cfg,subjects);






















%% Control Analyses

%Dots
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\ZeroMEG\analysis';
    cfg.mRDM_file = 'dot_control_rdm';
    cfg.num_predictors = 6;
    cfg.output_path = 'Analysis/MEG/RSA/Controls/Dots';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    RSA_DotControl(cfg,subject);
end
% Plot
colours = {'#E63946'};
figure('units','normalized','outerposition',[0 0 1 1])
model = 'dot_control_rdm';
cfg.linecolor = colours;
cfg.shadecolor = cfg.linecolor;
cfg.mRDM_file = model;
cfg.task = 'dots';
cfg.ylim = [-0.4 1];
cfg.title = 'Dot Stim-Set Control';
plot_mean_single_RSA(cfg,subjects)

% Arabic
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\ZeroMEG\analysis';
    cfg.mRDM_file = 'arabic_control_rdm';
    cfg.num_predictors = 6;
    cfg.output_path = 'Analysis/MEG/RSA/Controls/Arabic';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    RSA_ArabicControl(cfg,subject);
end
% Plot
model = 'arabic_control_rdm';
cfg.linecolor = {'blue'};
cfg.shadecolor = cfg.linecolor;
cfg.mRDM_file = model;
cfg.ylim = [-0.4 1];
cfg.task = 'arabic';
cfg.title = 'Arabic Colour Control';
plot_mean_single_RSA(cfg,subjects)
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
