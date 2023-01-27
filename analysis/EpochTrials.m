function EpochTrials(cfg0,subject)
% function CheckEpochTrials(cfg0,subjectID)
% Checks whether the epoching done by time matches triggers

saveDir                     = fullfile(cfg0.datadir,subject);
if ~exist(saveDir,'dir'); mkdir(saveDir); end

%% Arabic Datasets 
data = load(fullfile(cfg0.datadir,subject,'arabic_data.mat'));
data = struct2cell(data); arabic_data = data{1};
%% Create new trl matrix

% Get photodiode signal
cfg = [];
cfg.channel = {'UADC004'} ;
lightDiodeSignal = ft_preprocessing(cfg, arabic_data);


% Define samples prestim and poststim
trl = [];
presamples = cfg0.arabic_prestim * arabic_data.fsample;
postsamples = cfg0.arabic_poststim * arabic_data.fsample;
for iTrial = 1:length(lightDiodeSignal.trial)
    
    [~,ind] = mink(diff(lightDiodeSignal.trial{iTrial}),10); %get sample index of 10 stim-onset times per trial
    ind = sort(ind); %sort them from first to last

    for t = 1:length(ind) %loop over the 10 stims in each trial and make their own row in the trl matrix (i.e. make them their own trial)
        stimOn = ind(t)+arabic_data.sampleinfo(iTrial,1); % stim onset in samples relative to beginning of whole experiment
        trlbegin = round(stimOn - presamples); % start 0.075 s before stim on 
        trlend   = round(stimOn + postsamples); %end 0.8s after stim on
        offset   = round(presamples); %this represents where the stim comes on within the trial samples (i.e. the offset between trial start and stim start)
        newtrl   = [trlbegin trlend -offset];
        trl      = [trl; newtrl];
        
    end
    
    
end

%redefine trl
cfg =[];
cfg.trl = trl;
arabic_trials = ft_redefinetrial(cfg,arabic_data);

%Plot new, shorter, trials and check they are all aligned with the stim at 0
figure;
for i = 1:length(arabic_trials.time)
    plot(arabic_trials.time{1},arabic_trials.trial{i}(313,:))
    hold on
end
xline(0,'r')
title('Arabic Trials')
xlabel('Time')
ylabel('Photodiode Signal')

% Baseline Correct
cfgS                        = [];
cfgS.demean                 = 'yes'; % baseline correction on 75 ms before stim 
cfgS.baselinewindow         = [-0.075 0];
arabic_trials          = ft_preprocessing(cfgS,arabic_trials);

%Pivot the trialinfo. Columns: Run, trial number, task, numeral, colour, response, RT, correct
arabic_trials.trialinfo    = pivotTrialsArabic(arabic_trials.trialinfo);
% add trialnumbers for later
arabic_trials.trialnumbers = (1:length(arabic_trials.trial))';



save(fullfile(saveDir,cfg0.arabicSaveName),'arabic_trials','-v7.3')

clear trl arabic_trials arabic_data lightDiodeSignal

%% Dots
data = load(fullfile(cfg0.datadir,subject,'dot_data.mat'));
data = struct2cell(data); dot_data = data{1};

%% Create new trl matrix

% Get photodiode signal
cfg = [];
cfg.channel = {'UADC004'} ;
lightDiodeSignal = ft_preprocessing(cfg, dot_data);


% Define samples prestim and poststim
trl = [];
presamples = cfg0.dot_prestim * dot_data.fsample;
postsamples = cfg0.dot_poststim * dot_data.fsample;
for iTrial = 1:length(lightDiodeSignal.trial)
    

    [~,ind] = mink(diff(lightDiodeSignal.trial{iTrial}(1:800)),2); %get sample index of 2 stim-onset times per trial
    ind = sort(ind); %sort them from first to last

    for t = 1:length(ind) %loop over the 2 stims in each trial and make their own row in the trl matrix (i.e. make them their own trial)
        stimOn = ind(t)+dot_data.sampleinfo(iTrial,1); % stim onset in samples relative to beginning of whole experiment
        trlbegin = round(stimOn - presamples); % start 0.2 s before stim on 
        trlend   = round(stimOn + postsamples); %end 0.8s after stim on
        offset   = round(presamples); %this represents where the stim comes on within the trial samples (i.e. the offset between trial start and stim start)
        newtrl   = [trlbegin trlend -offset];
        trl      = [trl; newtrl];
        
    end
    
    
end

%redefine trl
cfg =[];
cfg.trl = trl;
dot_trials = ft_redefinetrial(cfg,dot_data);

%Plot new, shorter, trials and check they are all aligned with the stim at 0
figure;
for i = 1:length(dot_trials.time)
    plot(dot_trials.time{1},dot_trials.trial{i}(313,:))
    hold on
end
xline(0,'r')
title('Dot Trials')
xlabel('Time')
ylabel('Photodiode Signal')

% We don't baseline correct because we might want to look at development of activation from sample to test

%Pivot the trialinfo. Columns: Run, trial number, task, stim-set, sample-or-test, numerosity, match trial, response, RT, correct
dot_trials.trialinfo    = pivotTrialsDots(dot_trials.trialinfo);
% add trialnumbers for later
dot_trials.trialnumbers = (1:length(dot_trials.trial))';



save(fullfile(saveDir,cfg0.dotSaveName),'dot_trials','-v7.3')



end