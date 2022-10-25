function multiclass_loc(cfg,subject)

%%currently just set up to do multiclass numerical confusion plots

% output directory
outputDir = fullfile(cfg.root,cfg.outputDir,subject);
if ~exist(outputDir,'dir'); mkdir(outputDir); end
disp(fullfile(outputDir,string(cfg.outputName)))

%load data
disp('loading..')
disp(subject)
if strcmp(cfg.task,'detection')    
    data = load(fullfile(cfg.root,'CleanData',subject,'det_data.mat'));
    correctIdx = 9;
    data = struct2cell(data); data = data{1};
elseif strcmp(cfg.task,'number')
    data = load(fullfile(cfg.root,'CleanData',subject,'num_data.mat'));
    correctIdx = 19;
    data = struct2cell(data); data = data{1};
    label_index = 14; %index of trial labels
elseif strcmp(cfg.task,'Localizer')
    data = load(fullfile(cfg.root,'CleanData',subject,'data.mat'));
    data = struct2cell(data); data = data{1};
    trls = (data.trialinfo(:,2)==1 & data.trialinfo(:,4)==2); 
    label_index = 3;
else
    error('Task Not Recognised')
end
disp('loaded data')


% run number multiclass LDA 
cfgS = [];
if strcmp(cfg.task,'Localizer')
    cfgS.trials = trls;
end
cfgS.channel = cfg.channel;
data = ft_selectdata(cfgS,data);
cfgS = [];cfgS.keeptrials = true;cfgS.channel=cfg.channel;data = ft_timelockanalysis(cfgS,data);

for trial = 1:size(data.trial,1)
    data.trial(trial,:,:) = ft_preproc_smooth(squeeze(data.trial(trial,:,:)),cfg.nMeanS);
end

%timediagonal
cfgS = [] ;
cfgS.method          = 'mvpa';
cfgS.latency         = [];
cfgS.design          = data.trialinfo(:,label_index);
cfgS.features        = 'chan';
%cfgS.generalize      = 'time';
cfgS.mvpa            = [];
cfgS.mvpa.classifier = cfg.decoder;
cfgS.mvpa.metric     = cfg.metric;
cfgS.mvpa.k          = cfg.nFold;
cfgS.mvpa.repeat     = 1;
cfgS.mvpa.preprocess = cfg.preprocess;
stat = ft_timelockstatistics(cfgS,data);
if strcmp(cfg.metric, 'accuracy')
    acc = stat.accuracy;
   
    save(fullfile(outputDir,string(cfg.outputName)),'acc');
elseif strcmp(cfg.metric,'confusion')
    conf = stat.confusion;
    save(fullfile(outputDir,string(cfg.outputName)),'conf');
    disp('saved')
end

% plot
if cfg.plot
    figure;
    time = data.time;
    plot(time,acc,'LineWidth',1); 
    hold on; 
    
    plot(xlim,[0.25 0.25],'k--','LineWidth',2)
    ylim([0,1])
    xlabel('Time (s)'); ylabel('Accuracy');
    xlim([time(1) time(end)]); title(cfg.title)

end
end