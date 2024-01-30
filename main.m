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

%% Zero Project Analysis
subjects = {
    'sub001'
    };



%% Behavioural
for subj = 1:length(subjects)
    subject = subjects{subj};
    
    cfg.root = 'D:\bbarnett\Documents\Zero\data\Raw';
    
    BehaviourAnalysis(cfg,subject);
end

%% Preprocessing
for subj = 1:length(subjects)
    subject = subjects{subj};
    disp(subject)
    %{
    %experimental tasks
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\PreprocData';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data\Raw';
    cfg.eventvalue = 1;
    cfg.prestim = 0.2;
    cfg.poststim = 1;
    cfg.saveName = 'data_preproc';
    cfg.wildcard = '*SF025*.ds';
    cfg.localizer = false;
    cfg.plot = true;
    PreprocessingTrialsPD_BOB(cfg,subject);
    %}

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

    

   
    %check loc
    cfg = [];
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
    load(fullfile(cfg.datadir,'PreprocData',subject,'loc_data_preproc.mat'))
    
    % Eyeball data
    cfg = [];
    cfg.trials = 'all';
    cfg.channel = 'meg';
    tl_data = ft_timelockanalysis(cfg,data);
    figure; imagesc(tl_data.avg); xticklabels(-0.2:0.2:1); xticks(linspace(1,size(tl_data.time,2),numel(xticklabels)));

    
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


    %localizer task - can be more lenient on blink trials as stims on for
    %longer
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data\PreprocData';
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
    cfg.stimOn = [0 0.3]; 
    cfg.dataName = 'loc_data_preproc';
    cfg.saveName = 'loc_data_VAR';
    cfg.localizer = true;
    PreprocessingVAR_BOB(cfg,subject);

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
    cfg.inputData = 'both_tasks_VAR';
    PreprocessingICA_BOB(cfg,subject)
    
end

%% Split Data Sets By Task
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg=[];
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
    Split_Tasks(cfg,subject);
end

%% Analysis

%% eye ball data
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg = [];
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
    load(fullfile(cfg.datadir,'CleanData',subject,'loc_data.mat'))
    
    % Eyeball data
    cfg = [];
    cfg.trials = 'all';
    cfg.channel = 'meg';
    tl_data = ft_timelockanalysis(cfg,loc_data);
    figure; imagesc(tl_data.avg); xticklabels(-0.2:0.2:1); xticks(linspace(1,size(tl_data.time,2),numel(xticklabels)));
    
    cfg.layout = 'CTF275.lay';
    cfg.parameter = 'avg';
    %cfg.xlim = [0 1];
    figure; ft_topoplotER(cfg,tl_data);
end

%% Decoding with LDA

%Localizer
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.task = 'detection';
    cfg.outputDir = 'Analysis/MEG/detection/House_v_Nothing';
    cfg.outputName = 'binary_LDA';
    cfg.conIdx = {'data.trialinfo(:,4) == 1 & data.trialinfo(:,5) == 1'...
                    'data.trialinfo(:,4) == 1 & data.trialinfo(:,5) == 2'}; 
    cfg.correct = true; %correct trials only
    cfg.nFold = 5;
    cfg.nMeanS = 7; %smooth over 0.02 seconds;
    cfg.gamma = 0.1;
    cfg.plot = true;
    cfg.title = '';
    diagDecode(cfg,subject);
end

%plot mean localizer classifications
cfg = [];
cfg.root =  'D:\bbarnett\Documents\Zero\data';
cfg.accDir = 'Analysis/MEG/detection/House_v_Nothing';
cfg.accFile = 'binary_LDA.mat';
cfg.outputName = 'House_v_Nothing';
cfg.task = 'localizer';
cfg.title = 'Mean Accuracy Face V Nothing';
plot_mean_diag(cfg,subjects);



%Numerical Task
cfg = [];
cfg.root = 'D:\bbarnett\Documents\Zero\data';
cfg.task = 'number';
cfg.outputDir = 'Analysis/MEG/One_v_Two';
cfg.outputName = 'all_trials';
cfg.conIdx = {'data.trialinfo(:,14) == 1'...
                'data.trialinfo(:,14) == 2'}; %zero vs 3
cfg.correct = false; %correct trials only
cfg.nFold = 5;
cfg.nMeanS = 7; %smooth over 0.02 seconds;
cfg.gamma = 0.2;
cfg.plot = true;
cfg.title = 'One Vs. Two';
diagDecode(cfg,subject);

%Detection Task
cfg = [];
cfg.root = 'D:\bbarnett\Documents\Zero\data';
cfg.task = 'detection';
cfg.outputDir = 'Analysis/MEG/House_V_Face';
cfg.outputName = 'all_trials';
cfg.conIdx = {'data.trialinfo(:,14) == 1'...
                'data.trialinfo(:,14) == 2'}; %HOUSE V FACE edit this
cfg.correct = false; %correct trials only
cfg.nFold = 5;
cfg.nMeanS = 7; %smooth over 0.02 seconds;
cfg.gamma = 0.2;
cfg.plot = true;
cfg.title = 'House V Face';
diagDecode(cfg,subject);

%Decode Localizer
for subj = 1:length(subjects)
    figure;
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.outputDir = 'Analysis/MEG/Localizer';
    cfg.nFold = 5;
    cfg.nMeanS = 7; %smooth over 0.02 seconds;
    cfg.gamma = 0.2;
    cfg.plot = true;
    decodeLocalizer(cfg,subject);

end

classifiers = {'House' 'Face' 'Nothing' 'Zero' 'One' 'Two' 'Three'};
classifiers = {'Zero' 'One' 'Two' 'Three'};
classifiers = {'House' 'Face' 'Nothing'};
for c = 1:length(classifiers)
    classifier = classifiers{c};
    classifier_name = classifier;
        %Diag Decode Localizer One Vs All
        
        for subj = 1:length(subjects)
            subject = subjects{subj};
            classifier_name = classifier;
           
            cfg  = [];
            cfg.root = 'D:\bbarnett\Documents\Zero\data';
            cfg.task = 'detection';
            cfg.outputDir = fullfile('Analysis/MEG/',cfg.task,classifier_name,'_V_All');
            cfg.outputName = 'binary_LDA';
            cfg.classifier = c;%classifier index
            cfg.nFold = 5;
            cfg.nMeanS = 7; %smooth over 0.02 seconds;
            cfg.gamma = 0.1;
            cfg.plot = false;
            cfg.decoder = 'lda';
            cfg.title = strcat(classifier_name,' Vs all');
            diagDecodeOneVsAll(cfg,subject);
        
        end
        
       
        cfg.root =  'D:\bbarnett\Documents\Zero\data';
        cfg.accDir =  fullfile('Analysis/MEG/',cfg.task,classifier_name,'_V_All');
        cfg.accFile = 'binary_LDA.mat';
        cfg.outputName = strcat(classifier_name,'_V_All_LDA');
        cfg.title = strcat('Mean Accuracy',{' '},classifier_name,' V All');
        plot_mean_diag(cfg,subjects);
      
end


%% Decoding with Logistic Regression Classifier
%Localizer
cfg = [];
cfg.root = 'D:\bbarnett\Documents\Zero\data';
cfg.task = 'localizer';
cfg.outputDir = 'Analysis/MEG/Localizer/House_V_Face';
cfg.outputName = 'present';
cfg.conIdx = {'data.trialinfo(:,1) == 1'...
                'data.trialinfo(:,1) == 2'}; %house-present vs face-present
cfg.correct = false; %correct trials only
cfg.nFold = 5;
cfg.nMeanS = 7; %smooth over 0.02 seconds;
cfg.plot = true;
cfg.design = 'data.trialinfo(:,1)';
cfg.title = 'House V Face';
diagDecodeLog(cfg,subject);

%Numerical Task
cfg = [];
cfg.root = 'D:\bbarnett\Documents\Zero\data';
cfg.task = 'number';
cfg.outputDir = 'Analysis/MEG/One_v_Two';
cfg.outputName = 'all_trials';
cfg.conIdx = {'data.trialinfo(:,14) == 1'...
                'data.trialinfo(:,14) == 2'}; %zero vs 3
cfg.correct = false; %correct trials only
cfg.nFold = 5;
cfg.nMeanS = 7; %smooth over 0.02 seconds;
cfg.plot = true;
cfg.title = 'One Vs. Two';
cfg.design = 'data.trialinfo(:,14)'; %CHECK THIS
diagDecodeLog(cfg,subject);

%Detection Task
cfg = [];
cfg.root = 'D:\bbarnett\Documents\Zero\data';
cfg.task = 'detection';
cfg.outputDir = 'Analysis/MEG/House_V_Face';
cfg.outputName = 'all_trials';
cfg.conIdx = {'data.trialinfo(:,4) == 1 & data.trialinfo(:,5) == 1'...
                'data.trialinfo(:,4) == 2 & data.trialinfo(:,5) ==1'}; %HOUSE V FACE edit this
cfg.correct = false; %correct trials only
cfg.nFold = 5;
cfg.nMeanS = 7; %smooth over 0.02 seconds;
cfg.plot = true;
cfg.design = 'data.trialinfo(:,4)'; %edit THIS
cfg.title = 'House V Face';
diagDecodeLog(cfg,subject);

%% Decode with Lasso Logistic Regression
classifiers = {'House' 'Face' 'Nothing' 'Zero' 'One' 'Two' 'Three'};
lambdas = [0.0022 0.01 0.05 0.1 0.15 0.2];
for c = 1:length(classifiers)
    classifier = classifiers{c};
        for l = 1:length(lambdas)
            lambda = lambdas(l);
            %Diag Decode Localizer One Vs All
            for subj = 1:length(subjects)
                subject = subjects{subj};
                classifier_name = classifier;
               
                cfg  = [];
                cfg.decoder = 'lassolog';
                cfg.root = 'D:\bbarnett\Documents\Zero\data';
                cfg.outputDir = strcat('Analysis/MEG/Localizer/',classifier_name,'_V_All');
                cfg.outputName = 'lassolog';
                cfg.classifier = c;%classifier index
                cfg.task = 'localizer';
                cfg.nFold =5;
                cfg.nMeanS = 7; %smooth over 0.02 seconds;
                cfg.lambda = lambda;
                cfg.plot = false;
                cfg.title = strcat(classifier_name,' Vs all');
                diagDecodeOneVsAll(cfg,subject);
            
            end
        
            cfg = [];
            cfg.root =  'D:\bbarnett\Documents\Zero\data';
            cfg.accDir =  strcat('Analysis/MEG/Localizer/',classifier_name,'_V_All');
            cfg.accFile = 'lassolog.mat';
            cfg.outputName = strcat(classifier_name,'_V_All_lassolog');
            cfg.task = 'localizer';
            cfg.title = strcat('Mean Accuracy',{' '},classifier_name,' V All',{' '},num2str(lambda));
            plot_mean_diag(cfg,subjects);
        end
        
      
end


%% Power Spectra
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg = [];
    cfg.datadir = 'D:\bbarnett\Documents\Zero\data';
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
cfg.xlim =[0 2];
cfg.zlim = 'maxmin';
cfg.layout = 'CTF275.lay';
%cfg.highlightchannel = {'MEG2612'}
%cfg.highlight = 'on';
%cfg.highlightcolor = [1 0 0];
%cfg.highlightsize = 15;
cfg.parameter = 'powspctrm'; % the default 'avg' is not present in the data
figure; ft_topoplotER(cfg,power); colorbar


%% Confusion Plots of Numerical Stims in Localiser 
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.task = 'Localizer';
    cfg.outputDir = strcat('Analysis/MEG/',cfg.task,'/NumConfusion/');

    cfg.decoder = 'multiclass_lda';
    cfg.outputName = cfg.decoder;
    cfg.nFold =5;
    cfg.nMeanS = 7; %smooth over 0.02 seconds;
    cfg.lambda = 0.1;
    cfg.plot = false;
    cfg.channel  = 'MEG';
    cfg.metric = {'confusion'};
    cfg.preprocess = {'undersample'};
    cfg.title = subject;
    multiclass(cfg,subject);
    
end
cfg.conf_file = cfg.decoder;
confusion_plots(cfg,subjects);

%% Multiclass Decoding of Number - Accuracy
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.task = 'number';
    cfg.outputDir = strcat('Analysis/MEG/',cfg.task,'/NumAcc/');
    cfg.decoder = 'multiclass_lda';
    cfg.outputName = cfg.decoder;
    cfg.nFold =5;
    cfg.nMeanS = 7; %smooth over 0.02 seconds;
    cfg.lambda = 0.1;
    cfg.plot = false;
    cfg.channel  = 'MEG';
    cfg.metric = 'accuracy';
    cfg.preprocess = {'undersample'};
    cfg.title = subject;
    multiclass(cfg,subject);
    
end
cfg.root =  'D:\bbarnett\Documents\Zero\data';
cfg.accDir =  strcat('Analysis/MEG/',cfg.task,'/NumAcc/');
cfg.accFile = 'multiclass_lda.mat';
cfg.outputName = strcat(cfg.decoder);
cfg.title = strcat('Multiclass decoding of number');
plot_mean_diag(cfg,subjects);

%% RSA 
for subj = 1:length(subjects)
    subject = subjects{subj};
    cfg  = [];
    cfg.root = 'D:\bbarnett\Documents\Zero\data';
    cfg.mRDM_path ='D:\bbarnett\Documents\Zero\scripts\analysis';
    cfg.mRDM_file = 'number_rdm';
    cfg.num_predictors = 4;
    cfg.output_path = strcat('Analysis/MEG/');
    cfg.outputName = 'RSA_over_time.mat';
    cfg.task = 'localizer';
    cfg.channels = 'MEG';
    RSA(cfg,subject);
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
legend({'','Numbers','','','','', 'Discrete Zero'})


cfg.linecolor = '#62A6E3';
cfg.shadecolor = '#62A6E3';
cfg.mRDM_file = 'no_sharing_rdm';
plot_mean_RSA(cfg,subjects)
legend({'','Domain General','','','','', 'Shared Absence','','','','','No Sharing'})

%% Trial and Error Section

%preprocessing checks
cfgP = [];
cfgP.hpfilter = 'yes';
cfgP.hpfreq = 0.1;
data = ft_preprocessing(cfgP,data);

%keep PCA components with 99% variance
cfg = [];
covar = zeros(numel(data.label));
for itrial = 1:numel(data.trial)
    currtrial = data.trial{itrial};
    covar = covar + currtrial*currtrial.';
end
[V,D]=eig(covar);
D = sort(diag(D),'descend');
D = D ./ sum(D);
Dcum = cumsum(D);
cfg.numcomponent = (find(Dcum>.99,1,'first'));
cfg.method = 'pca';
cfg.demean = 'no';
comp = ft_componentanalysis(cfg,data);

cfgT = [];cfgT.keeptrials = 'true'; timelock = ft_timelockanalysis(cfgT,comp);


cfgS             = [];
cfgS.keeptrials  = 'yes';
data1             = ft_timelockanalysis(cfgS,comp);

