function [trl] = trialfun_photodiadBOB(cfg)

%cfg.dataset = dataSets{5};
% read the header information and the events from the data
hdr   = ft_read_header(cfg.dataset);
%event = ft_read_event(cfg.dataset); %dont need the triggers from MEG
%because we use photodiode
raw   = ft_read_data(cfg.dataset,'header',hdr);

% number of samples before and after
presamples  = cfg.trialdef.prestim*hdr.Fs;
postsamples = cfg.trialdef.poststim*hdr.Fs;

%get first trigger sample
trig = strcmp(hdr.label,cfg.trialdef.eventtype);
trig = raw(trig,:);

%Find indexes of stim ons
stim_on_samples = find(diff(trig) == 1); 

%in case trigger is on at start of block (this must be an error). If we leave
%this, we miss our first trigger and the trials are out of sync with the
%trialMatrix.
%The trigger still turns off at the correct point, so we just move back
%from when the trigger turns off the length of each stim, and turn the
%trigger off before that point
if trig(1) ~= 0
    stim_off_samples = find(diff(trig) == -1); %find samples where triggers turns off
    stim_length = stim_off_samples(2) - stim_on_samples(1); %get length of stim in samples
    trig(1:(stim_off_samples(1)-stim_length)) = 0; %move one stim length back and rewrite trigger values before this point as 0
    trig((stim_off_samples(1)-stim_length):stim_off_samples(1)) = 1; %set samples between on and off as 1. Mostly this is already done but sometimes trigger starts with a weird value
    stim_on_samples =  find(diff(trig) == 1); %refind the trigger ons samples with new first event
    warning('Trigger was active at beginning of block. You may want to check photodiode code manually.')
end
fprintf('Found %d events using the computer trigger \n',length(stim_on_samples)) %should be ntrials in block

avITI = mean(diff(stim_on_samples))+std(diff(stim_on_samples)); %find number of samples 1 SD less than average ITI
trig_first_sample = stim_on_samples(1)+1; %get sample of first trigger

if cfg.plot
    
    f = figure;
    set(f,'Position',get(0,'screensize'));
    subplot(2,1,1);
    plot(trig,'color','red')
    title('computer event triggers')
end

% identify when the photo-diad is on
PD = strcmp(hdr.label,cfg.trialdef.pdiodetype);
PD = raw(PD,:); % get photo-diad signal
PD = smooth(PD,hdr.Fs/10); % smooth by 1 ms
if cfg.plot
    subplot(2,1,2);
    plot(PD);
    title('Photodiode and Computed Events')
    hold on
end

trimmed = false;
if PD(trig_first_sample-avITI > 0)
    trimmed = true;
    PD = PD(round(trig_first_sample-avITI):end); %remove portion before first internal trigger
    %save the cut off indexes to add back on
    cut_idxs = 1:round(trig_first_sample-avITI);
end


tmp = find(PD == 0); PD = PD(1:tmp(1)); % cut-off last part of zeros
%PD = detrend(PD); % remove low frequency drift 


PD_on = PD < (mean(PD)-std(PD)); %get when the PD is on (when is less than 1 SD below mean)
PD_on_idx = find(PD_on);


%add the cut off section from the start back in, so indexes algin with neural
%data
if trimmed
    PD_on = [zeros(cut_idxs(end),1); PD_on];
    PD_on_idx = PD_on_idx + cut_idxs(end);
end


% define trials based on this
nTrls       = cfg.trialdef.nTrls; 
trl         = [];

for t = 1:nTrls
    
    
    %get index of stim on for this trial
    %on_idx = PD_on_idx(find(diff(PD_on_idx) > 1)+1);
    on_idx = [PD_on_idx(1); PD_on_idx(find(diff(PD_on_idx) > 1)+1)]; %indexes of each stim onset
    
    stimOn = on_idx(t); %get index for start of this trial's stim onset
    %get index of all samples from pre stim to trial end
    idx = stimOn - presamples:stimOn+postsamples; %get full indexes from prestim to end of trial

    % check if we're still within the data
    if idx(1) > PD_on_idx(end)
        fprintf('Reached the end of the data at trial %d \n',t)
        return;
    elseif idx(end) > PD_on_idx(end)
        idx = idx(idx < PD_on_idx(end));
        fprintf('Cutting trial %d short because of end data \n',t);
    elseif sum(PD_on(idx)) == 0
        
        fprintf('Reached the end of the data at trial %d \n',t)
        return;
    end
    
 
    % define trial samples
    trlbegin = round(stimOn - presamples); % start 0.2 s before stim on 
    trlend   = round(stimOn + postsamples); %end 1s after stim on
    offset   = presamples; %this represents where the stim comes on within the trial samples (i.e. the offset between trial start and stim start)
    newtrl   = [trlbegin trlend -offset];
    trl      = [trl; newtrl]; 
    
    
   
end
if cfg.plot
    subplot(2,1,2)
    for trial = 1:length(trl)
        xline(trl(trial,1),'color','magenta','Alpha',0.3)
        hold off
    end
end
%check any trials overlapping in completed trl matrix
for i = 1:length(trl)
    if i < length(trl)-1
        if trl(i,2) > trl(i+1,1)
            warning('ERROR: TRIALS %d and %d OVERLAPPING',i,i+1)
        end
    end
end
%the below printed values should be sensible (i.e. not drastically
%different from all the other ITIs)
disp(trl(2,1)-trl(1,2))
disp(trl(end,1)-trl(end-1,2))
end

