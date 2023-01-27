function multiclass_cross(cfg0,subject)

%% Save Path
outputDir = fullfile(cfg0.root,cfg0.output_path,subject);
if ~exist(outputDir,'dir'); mkdir(outputDir); end 


%% Load MEG data
disp('loading..')
disp(subject)
dot_data = load(fullfile(cfg0.root,'CleanData',subject,'dot_trials.mat'));
dot_data = dot_data.dot_data;
dot_time = dot_data.time{1};
disp('loaded data')

arabic_data = load(fullfile(cfg0.root,'CleanData',subject,'arabic_trials.mat'));
arabic_data = arabic_data.arabic_data;  
arabic_time = arabic_data.time{1};
disp('loaded data')

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
cfgS.trials = arabic_data.trialinfo(:,6) ~= 0;
arabic_data = ft_selectdata(cfgS,arabic_data);

%% Select Overlapping Window
cfgS = [];
cfgS.toilim = [-0.0767 0.8];
dot_data = ft_redefinetrial(cfgS,dot_data);
dot_time = dot_data.time{1};

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
%% Time x Time Decoding
cfgS = [];
cfgS.classifier = 'multiclass_lda';
cfgS.metric = cfg0.metric;
cfgS.preprocess ={'undersample'};
cfgS.repeat = 1;
%Edited MVPA-Light function allows cross validation to be used with cross-decoding.
[results_train_arabic,~] = mv_classify_timextime_BOB(cfgS,smoothed_arabic_data,arabic_data.trialinfo(:,4),smoothed_dot_data,dot_data.trialinfo(:,5));
[results_train_dot,~] = mv_classify_timextime_BOB(cfgS,smoothed_dot_data,dot_data.trialinfo(:,5),smoothed_arabic_data,arabic_data.trialinfo(:,4));
%Get accuracy and confusion matrices separately
if length(cfg0.metric) > 1
    acc_mask = strcmp(cfg0.metric, 'acc'); acc_location = find(acc_mask); conf_location = find(~acc_mask);    
    train_arabic_acc = results_train_arabic{acc_location}';%coz mvpa light has axes switched
    train_arabic_conf = results_train_arabic{conf_location};
    train_dot_acc = results_train_dot{acc_location}';%coz mvpa light has axes switched
    train_dot_conf = results_train_dot{conf_location};
    %Save
    save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric{acc_location}]),'train_arabic_acc');
    save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric{acc_location}]),'train_dot_acc');
    save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric{conf_location}]),'train_arabic_conf');
    save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric{conf_location}]),'train_dot_conf');   
elseif length(cfg0.metric) == 1
    if strcmp(cfg0.metric, 'acc')
        train_arabic_acc = results_train_arabic'; 
        train_dot_acc = results_train_dot';
        %Save
        save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric{1}]),'train_arabic_acc');
        save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric{1}]),'train_dot_acc');
    elseif strcmp(cfg0.metric, 'conf')
        train_arabic_conf = results_train_arabic;
        train_dot_conf = results_train_dot;
        %Save
        save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric{1}]),'train_arabic_conf');
        save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric{1}]),'train_dot_conf');
    end
end



%% Plot
if cfg0.plot
    
     c_min = min([min(train_arabic_acc,[],'all'),min(train_dot_acc,[],'all')])-0.05;
    c_max = max([max(train_arabic_acc,[],'all'),max(train_dot_acc,[],'all')])+0.05;

    figure('units','normalized','outerposition',[0 0 1 1])

    subplot(1,2,1)
    imagesc(arabic_time,arabic_time,train_arabic_acc,[c_min,c_max]); axis xy; colorbar;
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet') 
    title('Train on Arabic, Test on Dots')

    subplot(1,2,2)
    imagesc(dot_time,dot_time,train_dot_acc,[c_min,c_max]); axis xy; colorbar; 
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet')
    title('Train on Dots, Test on Arabic')
end
end