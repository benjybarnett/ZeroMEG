function numDiscriminability(cfg0,subject)

%% Save Path
outputDir = fullfile(cfg0.root,cfg0.output_path,subject);
if ~exist(outputDir,'dir'); mkdir(outputDir); end 

%% Load MEG data
disp('loading..')
disp(subject)
dot_data = load(fullfile(cfg0.root,'CleanData',subject,'dot_trials.mat'));
dot_data = dot_data.dot_trials;
dot_time = dot_data.time{1};
disp('loaded data')

arabic_data = load(fullfile(cfg0.root,'CleanData',subject,'arabic_trials.mat'));
arabic_data = arabic_data.arabic_trials;  
arabic_time = arabic_data.time{1};
disp('loaded data')

outputDir = fullfile(cfg0.root,cfg0.output_path,subject);
if ~exist(outputDir,'dir'); mkdir(outputDir); end

%{
%% Try Separate Stim Types
cfg =[];
cfg.trials = num_data.trialinfo(:,13) == 2;
num_data = ft_selectdata(cfg,num_data);
num_labels = num_labels(num_data.trialinfo(:,13) == 2);
%}


%% Select Sample Dot Stims
cfgS = [];
cfgS.trials = dot_data.trialinfo(:,4) == 1;
dot_data = ft_selectdata(cfgS,dot_data);

%% Remove No Resp Trials
cfgS = [];
cfgS.trials = dot_data.trialinfo(:,8) ~= 0;
dot_data = ft_selectdata(cfgS,dot_data);
cfgS.trials = arabic_data.trialinfo(:,6) ~= 0 ;
arabic_data = ft_selectdata(cfgS,arabic_data);


%% Get Trial x Channels x Time Matrix For Each Task
cfgS = [];
cfgS.keeptrials = true;
cfgS.channel=cfg0.channel;
dot_data = ft_timelockanalysis(cfgS,dot_data);

cfgS = [];
cfgS.keeptrials = true;
cfgS.channel=cfg0.channel;
arabic_data = ft_timelockanalysis(cfgS,arabic_data);


%% Smooth Data
smoothed_dot_data = zeros(size(dot_data.trial));
for trial = 1:size(dot_data.trial,1)
    smoothed_dot_data(trial,:,:) = ft_preproc_smooth(squeeze(dot_data.trial(trial,:,:)),cfg0.nMeanS);
end
smoothed_arabic_data = zeros(size(arabic_data.trial));
for trial = 1:size(arabic_data.trial,1)
    smoothed_arabic_data(trial,:,:) = ft_preproc_smooth(squeeze(arabic_data.trial(trial,:,:)),cfg0.nMeanS);
end

%% Pairwise decode for each number
for num = 1:6

    %% Undersample Non-Target Class
    %So each non-zero numerosity appears the same number of times
    cfgB = [];
    cfgB.numNTClass = 5;
    [arabic_data_tmp,arabic_labels] = UndersampleBinarise(cfgB,smoothed_arabic_data,arabic_data.trialinfo(:,4)+1,num);
    [dot_data_tmp,dot_labels] = UndersampleBinarise(cfgB,smoothed_dot_data,dot_data.trialinfo(:,5)+1,num);
    
    %% Binarise labels
    arabic_labels = (arabic_labels == num)+1;
    dot_labels = (dot_labels == num)+1;
    
    %% Within Time x Time Decoding
    cfgS = [];
    cfgS.classifier = 'lda';
    cfgS.metric = 'auc';
    cfgS.preprocess ={'undersample'};%we dont avg samples here to increase number of trials for dot decoder
    cfgS.repeat = 1;
    [results_arabic,~] = mv_classify(cfgS,arabic_data_tmp,arabic_labels);
    [results_dot,~] = mv_classify(cfgS,dot_data_tmp,dot_labels);
   
    within_arabic_acc = results_arabic;
    within_dot_acc = results_dot;
    %Save
    save(fullfile(outputDir,[cfg0.output_prefix{1},'_',num2str(num-1)]),'within_arabic_acc');
    save(fullfile(outputDir,[cfg0.output_prefix{2},'_',num2str(num-1)]),'within_dot_acc');
  
    clear arabic_data_tmp dot_data_tmp

end


end