function [trl, event] = trialfun_photodiadND(cfg)

% read the header information and the events from the data
hdr   = ft_read_header(cfg.dataset);
event = ft_read_event(cfg.dataset);
raw   = ft_read_data(cfg.dataset,'header',hdr);

% number of samples before and after
presamples  = cfg.trialdef.prestim*hdr.Fs;
postsamples = cfg.trialdef.poststim*hdr.Fs;

% identify when the photo-diad is on
PD = strcmp(hdr.label,cfg.trialdef.eventtype);
PD = raw(PD,:); % get photo-diad signal
PD = smooth(PD,hdr.Fs/100); % smooth by 10 ms
tmp = find(PD == 0); PD = PD(1:tmp(1)); % cut-off last part of zeros
%PD = detrend(PD); % remove low frequency drift 
figure; plot(PD)
PD = PD(1:126612);
figure; plot(PD);
PD_on = PD < (mean(PD)-std(PD)); 
PD_on_idx = find(PD_on);
figure;plot(PD_on)

% define trials based on this
trialLength = (cfg.trialdef.poststim+cfg.trialdef.prestim-0.2)*hdr.Fs;
nTrls       = cfg.trialdef.nTrls; 
trl         = [];
trlTime     = [];

for t = 1:nTrls
    
    % idx for samples of this trial
    if t == 1
        idx = PD_on_idx(1)-presamples:PD_on_idx(1)+trialLength;
    else
        % base on trial end last trial
        idx = stimOff+(0.65*hdr.Fs):stimOff+(0.65*hdr.Fs)+trialLength;
    end
    
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
    
    PD_on_trl = PD_on(idx);
    PD_on_trl_idx = find(PD_on_trl);
    
    % define when cue and stimulus are on
    cueOn = idx(PD_on_trl_idx(1));
    cueOff = idx(PD_on_trl_idx(diff(PD_on_trl_idx)>1));
    if length(cueOff) > 1
        [a,b] = min(abs((((cueOff-cueOn)/1200)-0.5)));
        cueOff = cueOff(b);
        if a > 0.011
            error('Timing issues: check manually')
        end
    end
    
    stimOn = idx(PD_on_trl_idx(find(diff(PD_on_trl_idx)>1)+1));       
    if length(stimOn) > 1
        [a,b] = min(abs((((stimOn-cueOff)/1200)-0.7)));
        stimOn = stimOn(b);
        if a > 0.011
            error('Timing issues: check manually')
        end
    end
    
    stimOff = idx(PD_on_trl_idx(end));
    if length(stimOff) > 1
        [a,b] = min(abs((((stimOff-cueOn)/1200)-0.1)));
       stimOff = stimOff(b);
        if a > 0.011
            error('Timing issues: check manually')
        end
    end
    
    ntrlTime = [cueOn/hdr.Fs cueOff/hdr.Fs stimOn/hdr.Fs stimOff/hdr.Fs];
    trlTime  = [trlTime; ntrlTime];    
    
    % define trial samples
    trlbegin = round(stimOn - (1.4*hdr.Fs)); % start 1.2 s before stim on - which is cue-onset 
    trlend   = round(stimOn + (0.5*hdr.Fs));
    offset   = 0.2*hdr.Fs;
    newtrl   = [trlbegin trlend -offset];
    trl      = [trl; newtrl];       
   
end


end

