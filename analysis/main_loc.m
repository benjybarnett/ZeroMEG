clear all;
addpath(genpath('Utilities'))
addpath('D:\bbarnett\Documents\Zero\HMeta-d-master\Matlab')
addpath('D:\bbarnett\Documents\Zero\HMeta-d-master\CPC_metacog_tutorial\cpc_metacog_utils')
addpath('Decoding')
addpath('Decoding\plotting')
addpath('D:\bbarnett\Documents\Zero\fieldtrip-master-MVPA\')
addpath('D:/bbarnett/Documents/ecobrain/MVPA-Light\startup')
addpath('D:/bbarnett/Documents/Zero/liblinear-master/')
addpath('D:/bbarnett/Documents/Zero/liblinear-master/matlab')

addpath('C:\Users\bbarnett\AppData\Local\JAGS\JAGS-3.4.0\x64\bin')

% set deaults
ft_defaults;
startup_MVPA_Light

subjects = {
    'sub01'
    'sub02'

    
    };

%% Preprocessing
for subj = 1:length(subjects)
    subject = subjects{subj};

    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\localizer\PreprocData';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data\localizer';
    cfg.eventvalue = 1;
    cfg.prestim = 0.2;
    cfg.poststim = 1;
    cfg.saveName = 'loc_data_preproc';
    cfg.wildcard = '*SF025*.ds';
    cfg.localizer = false; %keep as false as this based on old localizer
    cfg.plot = true;
    PreprocessingTrialsPD_BOB(cfg,subject);

end

%% Visual Artefact Rejection
for subj = 1:length(subjects)
    subject= subjects{subj};

    %localizer task - can be more lenient on blink trials as stims on for
    %longer
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\localizer\PreprocData';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data\Raw\localizer';
    cfg.stimOn = [0 0.3]; 
    cfg.dataName = 'loc_data_preproc';
    cfg.saveName = 'loc_data_VAR';
    cfg.localizer = true;
    PreprocessingVAR_BOB(cfg,subject);

end

%% Independent Components Analysis (ICA)
for subj = 1:length(subjects)
    subject= subjects{subj};
    
    %both tasks
    cfg = [];
   cfg.root = 'D:\bbarnett\Documents\Zero\data\localizer\VARData';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data\localizer\';
    cfg.inputData = 'loc_data_VAR';
    PreprocessingICA_BOB(cfg,subject)
    
end

%% Analysis
cfg = [];
cfg.datadir = 'D:\bbarnett\Documents\Zero\data\localizer';
load(fullfile(cfg.datadir,'CleanData',subject,'data.mat'))

% Eyeball data
cfg = [];
cfg.trials = 'all';
cfg.channel = 'meg';
tl_data = ft_timelockanalysis(cfg,data);
figure; imagesc(tl_data.avg); xticklabels(-0.2:0.2:1); xticks(linspace(1,size(tl_data.time,2),numel(xticklabels)));

cfg.layout = 'CTF275.lay';
cfg.parameter = 'avg';
%cfg.xlim = [0 1];
figure; ft_topoplotER(cfg,tl_data);


%Localizer
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\localizer';
    cfg.task = 'localizer';
    cfg.outputDir = 'Analysis/MEG/Localizer/Two_V_Three';
    cfg.outputName = 'binary_LDA';
    cfg.conIdx = {'data.trialinfo(:,3) == 1 & data.trialinfo(:,2)==2'...
                    'data.trialinfo(:,3) == 3 & data.trialinfo(:,2)==2'}; 
    cfg.correct = false; %correct trials only
    cfg.nFold = 5;
    cfg.nMeanS = 7; %smooth over 0.02 seconds;
    cfg.gamma = 0.2;
    cfg.plot = true;
    cfg.title = 'two v three';
    diagDecode(cfg,subject);
end
cfg = [];
cfg.root =  'D:\bbarnett\Documents\Zero\data\localizer';
cfg.accDir = 'Analysis/MEG/Localizer/Two_V_Three';
cfg.accFile = 'binary_LDA.mat';
cfg.outputName = 'House_V_Face';
cfg.task = 'localizer';
cfg.title = 'Mean Accuracy House V Face';
plot_mean_diag(cfg,subjects);


%% Power Spectra
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg = [];
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data\localizer';
    load(fullfile(cfg.datadir,'CleanData',subject,'data.mat'))
    cfg = [];
    cfg.channel = 'MEG';
    data = ft_selectdata(cfg,data);
    
    %create power spectrum
    cfg = [];
    cfg.method = 'mtmfft';
    cfg.output = 'pow';
    cfg.channel = 'MEG';
    cfg.taper ='hanning';
    power= ft_freqanalysis(cfg,data);
    %power spectrum plot
    figure;
    hold on;
    xlim([0 60])
    %ylim([0 6e-27])
    plot(power.freq, power.powspctrm,'linewidth',1)
    xlabel('Frequency (Hz)')
    ylabel('Power (\mu V^2)')
    hold off
end

%plot topography of power spectrum. I.e. where on head were different
%frequencies
cfg = [];
cfg.xlim =[0 20];
cfg.zlim = 'maxmin';
cfg.layout = 'CTF275.lay';
%cfg.highlightchannel = {'MEG2612'}
%cfg.highlight = 'on';
%cfg.highlightcolor = [1 0 0];
%cfg.highlightsize = 15;
cfg.parameter = 'powspctrm'; % the default 'avg' is not present in the data
figure; ft_topoplotER(cfg,power); colorbar

%% Decoding one vs all
classifiers = {'House' 'Face' 'Nothing' 'Zero' 'One' 'Two' 'Three'};
for c= 1:length(classifiers)
    classifier_name = classifiers{c};
    for subj = 1:length(subjects)
        subject = subjects{subj};
        
       
        cfg  = [];
        cfg.decoder = 'lda';
        cfg.root = 'D:\bbarnett\Documents\Zero\data\localizer';
        cfg.outputDir = strcat('Analysis/MEG/Localizer/',classifier_name,'_V_All');
        cfg.outputName = 'lda';
        cfg.classifier = c;%classifier index
        cfg.task = 'localizer';
        cfg.nFold =5;
        cfg.nMeanS = 7; %smooth over 0.02 seconds;
        cfg.gamma = 0.1;
        cfg.plot = false;
        cfg.title = strcat(classifier_name,' Vs all');
        diagDecodeOneVsAllLOC(cfg,subject);
    
    end

    
    cfg.accDir =  cfg.outputDir;
    cfg.accFile = 'lda.mat';
    cfg.outputName = strcat(classifier_name,'_V_All_lda');
    cfg.task = 'localizer';
    cfg.title = strcat('Mean Accuracy',{' '},classifier_name,' V All');
    plot_mean_diag(cfg,subjects); 
end

%% Confusion Plots of Numerical Stims in Localiser 
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\localizer';
    cfg.task = 'Localizer';
    cfg.outputDir = strcat('Analysis/MEG/localizer/NumConfusion/');

    cfg.decoder = 'multiclass_lda';
    cfg.outputName = cfg.decoder;
    cfg.nFold =5;
    cfg.nMeanS = 7; %smooth over 0.02 seconds;
    cfg.lambda = 0.1;
    cfg.plot = false;
    cfg.channel  = 'MEG';
    cfg.metric = 'confusion';
    cfg.preprocess = {'undersample'};
    cfg.title = subject;
    multiclass_loc(cfg,subject);
    
end
cfg.conf_file = cfg.decoder;
confusion_plots(cfg,subjects);



%% RSA 
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\localizer';
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\analysis';
    cfg.mRDM_file = 'number_rdm';
    cfg.num_predictors = 4;
    cfg.output_path = strcat('Analysis/MEG/');
    cfg.outputName = 'RSA_over_time.mat';
    cfg.task = 'localizer';
    cfg.channels = 'MEG';
    RSA_loc(cfg,subject);
end
figure;
cfg.linecolor = '#ED217C';
cfg.shadecolor = '#ED217C';
cfg.mRDM_file = 'number_rdm';
plot_mean_RSA(cfg,subjects)

cfg.linecolor = '#1B998C';
cfg.shadecolor = '#1B998C';
cfg.mRDM_file = 'disc_zero';
plot_mean_RSA(cfg,subjects)

cfg.linecolor = '#62A6E3';
cfg.shadecolor = '#62A6E3';
cfg.mRDM_file = 'pos_numbers_rdm';
plot_mean_RSA(cfg,subjects)
legend({'','Number','','','','', 'Discrete Zero','','','','','Positive Numbers'})


%% Multiclass Decoding of Number - Accuracy
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\localizer';
    cfg.task = 'Localizer';
    cfg.outputDir = strcat('Analysis/MEG/',cfg.task,'/NumAcc/');
    cfg.decoder = 'multiclass_lda';
    cfg.outputName = cfg.decoder;
    cfg.nFold =5;
    cfg.nMeanS = 7; %smooth over 0.02 seconds;
    cfg.lambda = 0.1;
    cfg.plot = false;
    cfg.channel  = 'MEG';
    cfg.metric = 'accuracy';
    cfg.preprocess = {'undersample','zscore'};
    cfg.title = subject;
    multiclass_loc(cfg,subject);
    
end
cfg.root =  'D:\bbarnett\Documents\Zero\data\localizer';
cfg.accDir =  strcat('Analysis/MEG/',cfg.task,'/NumAcc/');
cfg.accFile = 'multiclass_lda.mat';
cfg.outputName = strcat(cfg.decoder);
cfg.title = strcat('Multiclass decoding of number');
plot_mean_diag(cfg,subjects);
