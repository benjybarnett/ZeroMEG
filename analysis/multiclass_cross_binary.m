function multiclass_cross_binary(cfg0,subject)

%% Save Path
outputDir = fullfile(cfg0.root,cfg0.output_path,subject);
if ~exist(outputDir,'dir'); mkdir(outputDir); end 

%% Load MEG data
disp('loading..')
disp(subject)
det_data = load(fullfile(cfg0.root,'CleanData',subject,'det_data.mat'));
det_data = det_data.det_data;  
det_labels = det_data.det_labels;

num_data = load(fullfile(cfg0.root,'CleanData',subject,'num_data.mat'));
num_data = num_data.num_data;  
num_labels = num_data.num_labels;
time = num_data.time{1};
disp('loaded data')

%% Organise Detection Data
% Use correct trials only and use present vs. absent as classification labels
cfgS = [];
cfgS.trials = det_data.trialinfo(:,9) == 1;
det_data = ft_selectdata(cfgS,det_data);
det_labels = det_data.trialinfo(:,7) ;

%% Binarise Number Data
for lbl = 1:length(num_labels)
    if num_labels(lbl) == 1
        lbls(lbl) = 1;
    else
        lbls(lbl) = 2;
    end
end
num_labels = lbls';

%% Get Trial x Channels x Time Matrix For Each Task
cfgS = [];
cfgS.keeptrials = true;
cfgS.channel=cfg0.channel;
det_data = ft_timelockanalysis(cfgS,det_data);

cfgS = [];
cfgS.keeptrials = true;
cfgS.channel=cfg0.channel;
num_data = ft_timelockanalysis(cfgS,num_data);

%% Smooth Data
smoothed_det_data = zeros(size(det_data.trial));
for trial = 1:size(det_data.trial,1)
    smoothed_det_data(trial,:,:) = ft_preproc_smooth(squeeze(det_data.trial(trial,:,:)),cfg0.nMeanS);
end
smoothed_num_data = zeros(size(num_data.trial));
for trial = 1:size(num_data.trial,1)
    smoothed_num_data(trial,:,:) = ft_preproc_smooth(squeeze(num_data.trial(trial,:,:)),cfg0.nMeanS);
end

%% Time x Time Decoding
cfgS = [];
cfgS.classifier = 'lda';
cfgS.metric = cfg0.metric;
cfgS.preprocess ={'undersample'};
cfgS.repeat = 1;
%Edited MVPA-Light function allows cross validation to be used with cross-decoding.
[results_train_num,~] = mv_classify_timextime_BOB(cfgS,smoothed_num_data,num_labels,smoothed_det_data,det_labels);
[results_train_det,~] = mv_classify_timextime_BOB(cfgS,smoothed_det_data,det_labels,smoothed_num_data,num_labels);
%Get accuracy and confusion matrices separately
if length(cfg0.metric) > 1
    acc_mask = strcmp(cfg0.metric, 'acc'); acc_location = find(acc_mask); conf_location = find(~acc_mask);    
    train_num_acc = results_train_num{acc_location}';%coz mvpa light has axes switched
    train_num_conf = results_train_num{conf_location};
    train_det_acc = results_train_det{acc_location}';%coz mvpa light has axes switched
    train_det_conf = results_train_det{conf_location};
    %Save
    save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric{acc_location}]),'train_num_acc');
    save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric{acc_location}]),'train_det_acc');
    save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric{conf_location}]),'train_num_conf');
    save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric{conf_location}]),'train_det_conf');   
elseif length(cfg0.metric) == 1
    if strcmp(cfg0.metric, 'acc')
        train_num_acc = results_train_num'; 
        train_det_acc = results_train_det';
        %Save
        save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric]),'train_num_acc');
        save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric]),'train_det_acc');
    elseif strcmp(cfg0.metric, 'conf')
        train_num_conf = results_train_num;
        train_det_conf = results_train_det;
        %Save
        save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric]),'train_num_conf');
        save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric]),'train_det_conf');
    end
end



%% Plot
if cfg0.plot
    
    c_min = min([train_num_acc;train_det_acc],[],'all')-0.05;
    c_max = max([train_num_acc;train_det_acc],[],'all')+0.05;

    figure('units','normalized','outerposition',[0 0 1 1])

    subplot(1,2,1)
    imagesc(time,time,train_num_acc,[c_min,c_max]); axis xy; colorbar;
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet') 
    title('Train on Numbers, Test on Detection')

    subplot(1,2,2)
    imagesc(time,time,train_det_acc,[c_min,c_max]); axis xy; colorbar; 
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet')
    title('Train on Detection, Test on Numbers')
end
end