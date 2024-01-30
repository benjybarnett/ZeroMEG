function EpochTrialsAlternative(cfg0,subject)
% epochs trials in a different way in case original script doesnt work 
% for example due to the PD signal being too noisy

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
figure;
for iTrial = 1:length(lightDiodeSignal.trial)
    %figure
    plot(lightDiodeSignal.trial{iTrial})
    hold on
    %lightDiodeSignal.trial{iTrial} = smoothdata(lightDiodeSignal.trial{iTrial},'gaussian',5);
    PD_on = lightDiodeSignal.trial{iTrial} < (mean(lightDiodeSignal.trial{iTrial})-(0.5*std(lightDiodeSignal.trial{iTrial}))); %get when the PD is on (when is less than 1 SD below mean)
    pdind = find(PD_on);
    %xline(pdind)
    [~,ind] = maxk(diff(pdind),10);
    ind = sort(pdind(ind+1))-2; %hard coded '-2' seems to align the photodiode better to 0
    %xline(ind)
    %%

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
    %{
    if arabic_trials.trialinfo(i,1) ~= arabic_trials.trialinfo(i-1,1)
        figure;
    end
    if any(isnan(arabic_trials.trial{i}(313,:)))
        disp('hello')
        continue
    end
    %}
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
cfgS.baselinewindow         = [-0.1 0];
arabic_trials          = ft_preprocessing(cfgS,arabic_trials);


%Pivot the trialinfo. Columns: Run, trial number, task, numeral, colour, response, RT, correct
arabic_trials.trialinfo    = pivotTrialsArabic(arabic_trials.trialinfo);
% add trialnumbers for later
arabic_trials.trialnumbers = (1:length(arabic_trials.trial))';



save(fullfile(saveDir,cfg0.arabicSaveName),'arabic_trials','-v7.3')


clear trl arabic_trials arabic_data lightDiodeSignal


end