function [cfg,data] = PreprocessingTrialsPD_BOB(cfg0,subject)
% function PreprocessingTrialsPD(subjectID)
% PD means photodiode - we preprocess with respect to the photodiode

%% Datasets 
if cfg0.localizer == false
    raw_data_dir = fullfile(cfg0.datadir,subject,'meg','raw');
else
    raw_data_dir = fullfile(cfg0.datadir,subject,'meg','raw','localizer');
end
dataSets = str2fullfile(raw_data_dir,cfg0.wildcard);
disp(dataSets(1))
nDataSets = length(dataSets);
sprintf('%i data sets found',nDataSets)


%% Some settings
saveDir                     = fullfile(cfg0.root,subject);
if ~exist(saveDir,'dir'); mkdir(saveDir); end
cfgS                        = [];
cfgS.continuous             = 'yes';
cfgS.dftfilter              = 'yes';
cfgS.demean                 = 'yes'; % baseline correction on 200 ms before cue 
cfgS.baselinewindow         = [-0.2 0];
%cfgS.padding                = 10;


%% Load behavioural data for trial info
if cfg0.localizer == false
    %change back to data.mat
    trialInfo = load(fullfile(cfg0.datadir,subject,'meg','trial_data','data.mat'));
    trialInfo = trialInfo.data;
    %trialInfo = trialInfo.trialMatrix; %remove when finished with localizer
    nTrls = 96;
else
    trialInfo = load(fullfile(cfg0.datadir,subject,'meg','trial_data','loc_data.mat'));
    trialInfo = trialInfo.loc_data;
    nTrls = 84;
end


% get the data per block 
dataS = cell(nDataSets,1);

for d = 1:nDataSets
    
    
    fprintf('\t GETTING THE DATA FOR BLOCK %d OUT OF %d \n',d,nDataSets)
    cfg                         = cfgS;
    cfg.dataset                 = dataSets{d};   
    %cfg.trialfun                = 'trialfun_photodiadBOB';
    cfg.trialdef.eventtype      = 'UPPT001';
    cfg.trialdef.eventvalue     = cfg0.eventvalue; % stimulus 1
    cfg.trialdef.pdiodetype     = 'UADC004';
    cfg.trialdef.prestim        = cfg0.prestim+0.1; %we add additional time in case PD alginment requires us to move trial's 0 point
    cfg.trialdef.poststim       = cfg0.poststim+0.1;
    cfg.trialdef.nTrls          = nTrls; % number of trials per block
    cfg.plot                   = cfg0.plot;
    cfg                         = ft_definetrial(cfg);
    
    % get it
    data                  = ft_preprocessing(cfg);    
    
    %align with photodiode
    cfg.prestim = cfg0.prestim;
    cfg.poststim = cfg0.poststim;
    dataS{d} = AlignPDiode(cfg,data);
    
end


% append data
cfgA = []; data = ft_appenddata(cfgA,dataS{:}); clear dataS

% add trialnumbers for later
data.trialnumbers = (1:length(data.trial))';

% add trial-info
data.trialinfo = trialInfo;

% downsample
cfg.resamplefs              = 300;
data                        = ft_resampledata(cfg, data); % resample the data

% fix sample info 
data = fixsampleinfo(data);
data = rmfield(data, 'cfg');

%remove trials with response in localizer task % MUST EDIT THIS FOR NEW LOCALISER
if cfg0.localizer
    cfgS = [];
    cfgS.trials = data.trialinfo(:,1) < 8; %select only trials where repsonse not required
    data = ft_selectdata(cfgS,data);
end

 

%{
%REMOVE AFTER LOC ANALYSIS
nback_idxs = [];
for row = 1:length(data.trialinfo)

    if row > 1

        if ((data.trialinfo(row,2) == data.trialinfo(row-1,2)) && (data.trialinfo(row,1) == data.trialinfo(row-1,1)))

            if data.trialinfo(row,3) == data.trialinfo(row-1,3)
                nback_idxs = [nback_idxs row];
            end
        end
    end
end
cfgS = [];
cfgS.trials = ones(length(data.trialinfo),1);
cfgS.trials(nback_idxs,:) = 0;
cfgS.trials = logical(cfgS.trials);
data = ft_selectdata(cfgS,data);
%}



% save and clean up
save(fullfile(saveDir,cfg0.saveName),'data','-v7.3')
clear cfg data

end
