clear all;
set(0,'DefaultFigureWindowStyle','docked');
%% SET WD
cd to_path

%% Paths
addpath('paths')


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
    %'sub007' 
    'sub008'
    'sub009'
    'sub010'
    'sub011'
    %'sub012' 
    %'sub013' 
    'sub014'
    %'sub015' 
    'sub016'
    'sub017'
    'sub018'
    'sub019'
    'sub020'
    'sub021'
    'sub022'
    'sub023'
    'sub024'
    'sub025'
    'sub026'
    'sub027'
    'sub028'
    %'sub029'
    }; 



%% Behavioural
subjCurves = {};
meanRTs = {};
arabic_acc = {};
dot_acc = {};
for subj = 1:length(subjects)
    subject = subjects{subj};
    
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\Raw';
    cfg.plot =0;
    [subjCurves{subj},meanRTs{subj},arabic_acc{subj},dot_acc{subj}] = BehaviourAnalysis(cfg,subject);
end
groupBehav(subjCurves,meanRTs,dot_acc,arabic_acc);

%% Preprocessing
for subj = 1:length(subjects)
    subject = subjects{subj};
    disp(subject)
    
    %experimental tasks
    cfg = [];
    cfg.root = 'PreprocData';
    cfg.datadir = 'Raw';
    cfg.dotEventValue = 3;
    cfg.arabicEventValue = 1;
    cfg.prestimArabic = 0.5;
    cfg.poststimArabic = 4;
    cfg.prestimDot = 0.2;
    cfg.poststimDot = 2.5;
    cfg.saveName = 'data_preproc';
    cfg.wildcard = '*XXX*.ds';
    cfg.plot = true;
    PreprocessingTrialsPD_BOB(cfg,subject);

end

%% Visual Artefact Rejection
for subj = 1:length(subjects)
    subject= subjects{subj};

    %arabic task
    cfg = [];
    cfg.root = 'PreprocData';
    cfg.datadir = data';
    cfg.stimOn = [0 0]; 
    cfg.dataName = 'arabic_data_preproc';
    cfg.saveName = 'arabic_data_VAR';
    cfg.blinks = 0;
    PreprocessingVAR_BOB(cfg,subject);
   
    %dot
    cfg = [];
    cfg.root = 'PreprocData';
    cfg.datadir = 'data';
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
    cfg.root = 'VARData';
    cfg.datadir = data';
    cfg.inputData = 'arabic_data_VAR';
    cfg.compOutput = 'arabic_comp';
    cfg.outputData = 'arabic_data';
    PreprocessingICA_BOB(cfg,subject)
    
    %dot
    cfg = [];
    cfg.root = 'VARData'; 
    cfg.datadir = data';
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
    cfg.root = 'data\';
    cfg.datadir = 'CleanData';
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
    cfg.datadir = 'data';
    cfg.trials = 'all';
    cfg.channel = 'meg';
    cfg.file_name = 'arabic_trials';
    cfg.layout = 'CTF275.lay';
    cfg.datatype = 'CleanData';
    EyeballData(cfg,subject);

    %eyeball dot task
    cfg.file_name = 'dot_trials';
    EyeballData(cfg,subject);
end


%% Representations of Zero RSA
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'data';
    cfg.mRDM_path ='analysis';
    cfg.mRDM_file = 'graded_zero_rdm';
    cfg.num_predictors = 6;
    cfg.output_path = 'Zero';
    cfg.dot_output_folder = 'dots';
    cfg.arabic_output_folder = 'arabic';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    cfg.plot = false;
    RSA_Zero(cfg,subject);
end


%% Within Condition Multiclass Decoding
progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'data';
    cfg.output_path = 'Multiclass_Decoding/OverTime';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.metric = {'acc','conf'};
    cfg.output_prefix =  {'within_arabic_','within_dot_'}; %must be number data first
    cfg.plot = false;
    cfg.channel = 'MEG';
    multiclass(cfg,subject);
    progressbar(subj/length(subjects)); 
end

%% Cross Condition Multiclass Decoding
progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'data';
    cfg.output_path = 'Multiclass_Decoding/OverTime';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.metric = {'acc','conf'};
    cfg.output_prefix =  {'cross_arabic_','cross_dot_'}; %must be number data first
    cfg.plot = false;
    cfg.channel = 'MEG';
    cfg.sysRemove =false;
    cfg.pca = false;
    multiclass_cross(cfg,subject);
    progressbar(subj/length(subjects)); 
end


%% Within Condition Zero V All Decoding
progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'data';
    cfg.output_path = 'Zero_Decoding/OverTime';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.metric = {'acc','conf'};
    cfg.output_prefix =  {'within_arabic_','within_dot_'}; %must be number data first
    cfg.plot = false;
    cfg.channel = 'MEG';
    cfg.pca = false;
    cfg.sysRemove = false;
    decodeZeroVAll(cfg,subject);
    progressbar(subj/length(subjects));
end

%% Cross Condition Zero V All Decoding
progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'data';
    cfg.output_path = 'Zero_Decoding/OverTime';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.metric = {'acc','conf'};
    cfg.output_prefix =  {'train_arabic_','train_dot_'}; %must be number data first
    cfg.plot = false;
    cfg.channel = 'MEG';
    cfg.pca = false;
    cfg.sysRemove = false;
    decodeZeroVAll_cross(cfg,subject);
    progressbar(subj/length(subjects));  
end

%% Cross Condition Zero V Each Number Binary Decoding
progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'data';
    cfg.output_path = 'Zero_Decoding/OverTime/Individual';
    cfg.channels = 'MEG';
    cfg.nMeanS = 7;
    cfg.output_prefix =  {'train_arabic_','train_dot_'}; %must be number data first
    cfg.plot = false;
    cfg.channel = 'MEG';
    decodeZeroVEach_cross(cfg,subject);
    progressbar(subj/length(subjects));  
end



%% Cross Condition RSA
progressbar;
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'data';
    cfg.mRDM_path ='analysis';
    cfg.mRDM_file = 'shared_numbers_rdm';
    cfg.num_predictors = 12;
    cfg.output_path = 'Analysis/MEG/RSA/CrossModality';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    cfg.plot = false;
    cfg.removeDiag = true;

    RSA_Cross(cfg,subject);
    progressbar(subj/length(subjects));

end


%% Representation of Number: Confusion Matrix
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'data';

    cfg.output_path = 'Multiclass_Decoding/TimeAveraged';
    cfg.outputName = 'number_confusion';
    cfg.arabic_timepoints = [0.0567 0.8];
    cfg.dot_timepoints = [0.07 0.8];
    cfg.channel = 'MEG';
    NumberConfusion(cfg,subject);
end

%% Dots Control
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'data';
    cfg.mRDM_path ='ZeroMEG\analysis';
    cfg.mRDM_file = 'dot_control_rdm';
    cfg.num_predictors = 12;
    cfg.output_path = 'Analysis/MEG/RSA/Controls/Dots';
    cfg.outputName = 'RSA_over_time.mat';
    cfg.channels = 'MEG';
    RSA_DotControl(cfg,subject);
end

