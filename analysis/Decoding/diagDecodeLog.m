function num_trials = diagDecodeLog(cfg0,subject)

% output directory
outputDir = fullfile(cfg0.root,cfg0.outputDir,subject);
if ~exist(outputDir,'dir'); mkdir(outputDir); end

%load data
disp('loading..')
disp(subject)
if strcmp(cfg0.task,'detection')    
    data = load(fullfile(cfg0.root,'CleanData',subject,'det_data.mat'));
    correctIdx = 9;
elseif strcmp(cfg0.task,'number')
    data = load(fullfile(cfg0.root,'CleanData',subject,'num_data.mat'));
    correctIdx = 19;
elseif strcmp(cfg0.task,'localizer')
    data = load(fullfile(cfg0.root,'CleanData',subject,'loc_data.mat'));
else
    error('Task Not Recognised')
end
data = struct2cell(data); data = data{1};
disp('loaded data')


% select ony MEG channels  and appropriate trials
if ~cfg0.correct
    trls = eval(strcat('(',cfg0.conIdx{1}," | ",cfg0.conIdx{2}, ')' ));
else
    trls = eval(strcat('(',cfg0.conIdx{1}," | ",cfg0.conIdx{2},") & data.trialinfo(:,",num2str(correctIdx),")== 1"));
    
end
cfgS             = [];
cfgS.channel     = 'MEG';
cfgS.trials      = trls;
cfgS.keeptrials  = 'yes';
data             = ft_timelockanalysis(cfgS,data);


% check if this analysis already exists
%if ~exist(fullfile(outputDir,[cfg0.outputName '.mat']),'file')
    
    for trial = 1:size(data.trial,1)
        data.trial(trial,:,:) = ft_preproc_smooth(squeeze(data.trial(trial,:,:)),cfg0.nMeanS);
    end
    
    %diagonal decoding
    cfgS = [] ;
    cfgS.method          = 'mvpa';
    cfgS.latency         = [];
    cfgS.design          = eval(cfg0.design);
    cfgS.features        = 'chan';
    cfgS.mvpa.classifier = 'logreg';
    cfgS.mvpa.metric     = 'accuracy';
    cfgS.mvpa.k          = cfg0.nFold;
    cfgS.mvpa.repeat     = 1;
    cfgS.mvpa.preprocess = {'undersample', 'zscore'};
    cfgS.mvpa.hyperparameter.reg = 'l2';
    cfgS.mvpa.hyperparameter.lambda = [0.01,0.02,0.03,0.04,0.05,0.06,0.07,0.08,0.09,0.1,0.2,0.3,0.4,0.5];
    stats = ft_timelockstatistics(cfgS,data);
    acc = stats.accuracy;
    
    
    %save(fullfile(outputDir,'Log',string(cfg0.outputName{1})),'acc');


    %{

else
    warning('Analysis already exists, loading for plotting');
    load(fullfile(outputDir,cfg0.outputName),'Accuracy');
end
    %}


% plot
if cfg0.plot
     figure;
    time = stats.time;
    plot(time,acc,'LineWidth',1); 
    hold on; 
    
    plot(xlim,[0.5 0.5],'k--','LineWidth',2)
    ylim([0,1])
    xlabel('Time (s)'); ylabel('Accuracy');
    xlim([time(1) time(end)]); title(cfg0.title)


end