function multiclass(cfg0,subject)

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
cfgS.trials = arabic_data.trialinfo(:,6) ~= 0;
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

%% Time x Time Decoding
cfgS = [];
cfgS.classifier = 'multiclass_lda';
cfgS.metric = cfg0.metric;
cfgS.preprocess ={'undersample','average_samples'};
cfgS.repeat = 1;
[results_arabic,~] = mv_classify_timextime(cfgS,smoothed_arabic_data,arabic_data.trialinfo(:,4));
[results_dot,~] = mv_classify_timextime(cfgS,smoothed_dot_data,dot_data.trialinfo(:,5));
%Get accuracy and confusion matrices separately
if length(cfg0.metric) > 1
    acc_mask = strcmp(cfg0.metric, 'acc'); acc_location = find(acc_mask); conf_location = find(~acc_mask);    
    within_arabic_acc = results_arabic{acc_location}';%coz mvpa light has axes switched
    within_arabic_conf = results_arabic{conf_location};
    within_dot_acc = results_dot{acc_location}';%coz mvpa light has axes switched
    within_dot_conf = results_dot{conf_location};
    %Save
    save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric{acc_location}]),'within_arabic_acc');
    save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric{acc_location}]),'within_dot_acc');
    save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric{conf_location}]),'within_arabic_conf');
    save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric{conf_location}]),'within_dot_conf');   
elseif length(cfg0.metric) == 1
    if strcmp(cfg0.metric, 'acc')
        within_arabic_acc = results_arabic'; 
        within_dot_acc = results_dot';
        %Save
        save(fullfile(outputDir,[cfg0.output_prefix{1} cfg0.metric{1}]),'within_arabic_acc');
        save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric{1}]),'within_dot_acc');
    elseif strcmp(cfg0.metric, 'conf')
        within_arabic_conf = results_arabic;
        within_dot_conf = results_dot;
        %Save
        save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric{1}]),'within_arabic_conf');
        save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric{2}]),'within_dot_conf');
    end
end



%% Plot
if cfg0.plot
    
    c_min = min([min(within_arabic_acc,[],'all'),min(within_dot_acc,[],'all')])-0.05;
    c_max = max([max(within_arabic_acc,[],'all'),max(within_dot_acc,[],'all')])+0.05;
    
   
    figure('units','normalized','outerposition',[0 0 1 1])

    subplot(1,2,1)
    imagesc(arabic_time,arabic_time,within_arabic_acc,[c_min,c_max]); axis xy; colorbar;
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet') 
    title('Within Arabic')

    subplot(1,2,2)
    imagesc(dot_time,dot_time,within_dot_acc,[c_min,c_max]); axis xy; colorbar; 
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet')
    title('Within Dots')
end
end