function [cfg,data] = EpochTrials(cfg0,subject)
% function PEpochTrials(cfg0,subjectID)
% Epochs already preprocessed trials into shorter stim-based trials

%% Datasets 
load(fullfile(cfg0.datadir,subject,'dot_data.mat'));
load(fullfile(cfg0.datadir,subject,'arabic_data.mat'));

%% Arabic Epoching First

% Some settings
saveDir                     = fullfile(cfg0.datadir,subject);
if ~exist(saveDir,'dir'); mkdir(saveDir); end
cfgS                        = [];
cfgS.demean                 = 'yes'; % baseline correction on 75 ms before stim 
cfgS.baselinewindow         = [-0.075 0];
%cfgS.padding                = 10;


cfg                         = cfgS;
cfg.toilim                  = [-0.075 4];
temp                        = ft_redefinetrial(cfg,arabic_data);
cfg.toilim                  = [];
cfg.length                  = 0.875; %length of individual trials (0.075 pre stim, 0.8 post stim)
cfg.overlap                 = 0.6; %2nd stim pre-stim period starts at 0.275. So overlap with first stim epoch is 0.8-0.275, which = 0.525 seconds of overlap. This expressed as a fraction of the total 0.875 trial is 0.6 (0.525/0.925)
temp2                       = ft_redefinetrial(cfg,temp);


%Make all time axes the same for each trial
for t = 1:size(temp2.time,2)
    temp2.time{t} = temp2.time{1};
end

% Baseline correct
arabic_data              = ft_preprocessing(cfg,temp2); 
%Pivot the trialinfo. Columns: Run, trial number, task, numeral, colour, response, RT, correct
arabic_data.trialinfo    = pivotTrialsArabic(arabic_data.trialinfo);

% add trialnumbers for later
arabic_data.trialnumbers = (1:length(arabic_data.trial))';



%% Now Dot Task
% Some settings
cfgS                        = [];
cfgS.demean                 = 'yes'; % baseline correction on 200 ms before stim 
cfgS.baselinewindow         = [-0.2 0];
%cfgS.padding                = 10;


cfg                         = cfgS;
cfg.toilim                  = [-0.2 2.1]; %this covers both sample and test stim and delays
temp                        = ft_redefinetrial(cfg,dot_data);
cfg.toilim                  = [];

% Baseline correct as one trial (this is different to arabic task where we baseline correct each numeral separately)
temp2                       = ft_preprocessing(cfg,temp); 

%split sample and test stims
cfg.length                  = 1; %length of individual trials (0.2 pre stim, 0.8 post stim)
cfg.overlap                 = 0; %no overlap here. test stim starts at 0.8s, which is when epoch for sample stim ends
dot_data                    = ft_redefinetrial(cfg,temp2);

%Pivot the trialinfo. Columns: Run, trial number, task, stim-set, sample-or-test, numerosity, match trial, response, RT, correct
dot_data.trialinfo          = pivotTrialsDots(dot_data.trialinfo);

% add trialnumbers for later
dot_data.trialnumbers = (1:length(dot_data.trial))';

%Make all time axes the same for each trial
%we do this after BL correction in dot trials because we don't want to BL correct test stims

%currently commented out because we want the time axes for the test stims to be diffferent from the sample stims
%for t = 1:size(temp2.time,2)
 %   temp2.time{t} = temp2.time{1};
%end

% save and clean up
save(fullfile(saveDir,cfg0.dotSaveName),'dot_data','-v7.3')
save(fullfile(saveDir,cfg0.arabicSaveName),'arabic_data','-v7.3')

clear cfg dot_data arabic_data temp temp2

end
