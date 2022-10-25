function multiclass_cross_det(cfg0,subject)

%% Save Path
outputDir = fullfile(cfg0.root,cfg0.output_path,subject);
if ~exist(outputDir,'dir'); mkdir(outputDir); end 

%% Load MEG data
disp('loading..')
disp(subject)
det_data = load(fullfile(cfg0.root,'CleanData',subject,'det_data.mat'));
det_data = det_data.det_data;  
det_labels = det_data.det_labels;


%% Organise Detection Data
% Only keep trials with detection and confidence responses
cfgS = [];
cfgS.trials =~(det_data.no_det_resp);
det_data = ft_selectdata(cfgS,det_data);

%Get house trials
cfgS = [];
cfgS.trials =det_data.trialinfo(:,4) == 1;
house_data = ft_selectdata(cfgS,det_data);
house_labels = det_labels(det_data.trialinfo(:,4) == 1);
%Get face trials
cfgS = [];
cfgS.trials =det_data.trialinfo(:,4) == 2;
face_data = ft_selectdata(cfgS,det_data);
face_labels = det_labels(det_data.trialinfo(:,4) == 2);


%% Get Trial x Channels x Time Matrix For Each Task
cfgS = [];
cfgS.keeptrials = true;
cfgS.channel=cfg0.channel;
house_data = ft_timelockanalysis(cfgS,house_data);

cfgS = [];
cfgS.keeptrials = true;
cfgS.channel=cfg0.channel;
face_data = ft_timelockanalysis(cfgS,face_data);

%% Smooth Data
smoothed_house_data = zeros(size(house_data.trial));
for trial = 1:size(house_data.trial,1)
    smoothed_house_data(trial,:,:) = ft_preproc_smooth(squeeze(house_data.trial(trial,:,:)),cfg0.nMeanS);
end

smoothed_face_data = zeros(size(face_data.trial));
for trial = 1:size(face_data.trial,1)
    smoothed_face_data(trial,:,:) = ft_preproc_smooth(squeeze(face_data.trial(trial,:,:)),cfg0.nMeanS);
end

%% Time x Time Decoding
cfgS = [];
cfgS.classifier = 'multiclass_lda';
cfgS.metric = cfg0.metric;
cfgS.preprocess ={'undersample'};
cfgS.repeat = 1;
%Edited MVPA-Light function allows cross validation to be used with cross-decoding.
[results_train_house,~] = mv_classify_timextime_BOB(cfgS,smoothed_house_data,house_labels,smoothed_face_data,face_labels);
[results_train_face,~] = mv_classify_timextime_BOB(cfgS,smoothed_face_data,face_labels,smoothed_house_data,house_labels);
%Get accuracy and confusion matrices separately
if length(cfg0.metric) > 1
    acc_mask = strcmp(cfg0.metric, 'acc'); acc_location = find(acc_mask); conf_location = find(~acc_mask);    
    train_house_acc =results_train_house{acc_location}';%coz mvpa light has axes switched
    train_house_conf = results_train_house{conf_location};
    train_face_acc = results_train_face{acc_location}';%coz mvpa light has axes switched
    train_face_conf = results_train_face{conf_location};
    %Save
    save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric{acc_location}]),'train_house_acc');
    save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric{acc_location}]),'train_face_acc');
    save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric{conf_location}]),'train_house_conf');
    save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric{conf_location}]),'train_face_conf');   
elseif length(cfg0.metric) == 1
    if strcmp(cfg0.metric, 'acc')
        train_house_acc = results_train_house'; 
        train_face_acc = results_train_face';
        %Save
        save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric]),'train_house_acc');
        save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric]),'train_face_acc');
    elseif strcmp(cfg0.metric, 'conf')
        train_house_conf = results_train_house;
        train_face_conf = results_train_face;
        %Save
        save(fullfile(outputDir,[cfg0.output_prefix{1},cfg0.metric]),'train_house_conf');
        save(fullfile(outputDir,[cfg0.output_prefix{2},cfg0.metric]),'train_face_conf');
    end
end



%% Plot
if cfg0.plot
    
    c_min = min([train_num_acc;train_face_acc],[],'all')-0.05;
    c_max = max([train_num_acc;train_face_acc],[],'all')+0.05;

    figure('units','normalized','outerposition',[0 0 1 1])

    subplot(1,2,1)
    imagesc(time,time,train_num_acc,[c_min,c_max]); axis xy; colorbar;
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet') 
    title('Train on Numbers, Test on Detection')

    subplot(1,2,2)
    imagesc(time,time,train_face_acc,[c_min,c_max]); axis xy; colorbar; 
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    colormap('jet')
    title('Train on Detection, Test on Numbers')
end
end