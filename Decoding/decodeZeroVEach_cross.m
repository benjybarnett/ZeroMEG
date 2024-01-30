function decodeZeroVEach_cross(cfg0,subject)

%% Decodes Zero vs each number separately in binary,cross-modal fashion. 
%This is to examine the discrimnability of 0 vs other numbers across domains. 
% To see if we still see a graded 0 in the cross-domain case. Should see that
% 0 is most discriminable from 5, and least from 1

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

%% Only select overlapping time points
cfgS = [];
cfgS.latency = [min(arabic_time),max(arabic_time)];
dot_data = ft_selectdata(cfgS,dot_data);

%% Smooth Data
smoothed_dot_data = zeros(size(dot_data.trial));
for trial = 1:size(dot_data.trial,1)
    smoothed_dot_data(trial,:,:) = ft_preproc_smooth(squeeze(dot_data.trial(trial,:,:)),cfg0.nMeanS);
end
smoothed_arabic_data = zeros(size(arabic_data.trial));
for trial = 1:size(arabic_data.trial,1)
    smoothed_arabic_data(trial,:,:) = ft_preproc_smooth(squeeze(arabic_data.trial(trial,:,:)),cfg0.nMeanS);
end

for num = 1:5
    smoothed_arabic_data_tmp = smoothed_arabic_data(arabic_data.trialinfo(:,4) == 0 | arabic_data.trialinfo(:,4) == num,:,:);
    arabic_labels = arabic_data.trialinfo(arabic_data.trialinfo(:,4) == 0 | arabic_data.trialinfo(:,4) == num,4);
    smoothed_dot_data_tmp = smoothed_dot_data(dot_data.trialinfo(:,5) == 0 | dot_data.trialinfo(:,5) == num,:,:);
    dot_labels = dot_data.trialinfo(dot_data.trialinfo(:,5) == 0 | dot_data.trialinfo(:,5) == num,5);

    %Fix labels
    arabic_labels = (arabic_labels == 0)+1;
    dot_labels = (dot_labels == 0)+1;

    cfgS = [];
    cfgS.classifier = 'lda';
    cfgS.metric = 'auc';
    cfgS.preprocess ={'undersample','average_samples'};
    cfgS.repeat = 1;
    [train_arabic_auc,~] = mv_classify_timextime(cfgS,smoothed_arabic_data_tmp,arabic_labels,smoothed_dot_data_tmp,dot_labels);
    [train_dot_auc,~] = mv_classify_timextime(cfgS,smoothed_dot_data_tmp,dot_labels,smoothed_arabic_data_tmp,arabic_labels);

    train_arabic_auc = diag(train_arabic_auc');%coz mvpa light has axes switched
    train_dot_auc = diag(train_dot_auc');%coz mvpa light has axes switched

    save(fullfile(outputDir,[cfg0.output_prefix{1},'0_vs_',num2str(num)]),'train_arabic_auc');
    save(fullfile(outputDir,[cfg0.output_prefix{2},'0_vs_',num2str(num)]),'train_dot_auc');

end


end
