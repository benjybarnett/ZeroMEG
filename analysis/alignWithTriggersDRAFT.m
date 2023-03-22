function dataMain = AlignPDiode(cfg0,data)

close all; 
    cfg = [];
    cfg.channel = cfg0.trialdef.pdiodetype ;
    lightDiodeSignal = ft_preprocessing(cfg, data);

    cfg.channel = 'UPPT001';
    triggerSignal = ft_preprocessing(cfg,data);


    

    % determine the onset of the visual stimulus
    visOnset = [];
    for iTrial = 1:length(lightDiodeSignal.trial)
       
        PD_on = lightDiodeSignal.trial{iTrial} < (mean(lightDiodeSignal.trial{iTrial})-std(lightDiodeSignal.trial{iTrial})); %get when the PD is on (when is less than 1 SD below mean)
        PD_on_idx = find(PD_on);   
        visOnset(iTrial) = lightDiodeSignal.time{iTrial}(PD_on_idx(1));
       
    end
    
    %figure;
    %scatter(1:length(visOnset),visOnset)
    
    figure;
    for i = 2:length(lightDiodeSignal.time)
        
        plot(lightDiodeSignal.time{i},lightDiodeSignal.trial{i})
        hold on
        plot(triggerSignal.time{i},triggerSignal.trial{i},'Color','cyan')
        hold on
       
    end
    xline(0,'r')
    title('Unaligned Trials')
   

    % realign the trials to this onset
    cfg = [];
    cfg.offset = -visOnset * data.fsample;
    dataMain = ft_redefinetrial(cfg, data);
    
    
    %plot New redefined trials
    cfg = [];
    cfg.channel = cfg0.trialdef.pdiodetype ;
    lightDiodeSignal = ft_preprocessing(cfg, dataMain);
    cfg.channel = 'UPPT001';
    triggerSignal = ft_preprocessing(cfg,dataMain);

  figure;
    for i = 2:length(lightDiodeSignal.time)
        plot(lightDiodeSignal.time{i},lightDiodeSignal.trial{i})
        hold on
        plot(triggerSignal.time{i},triggerSignal.trial{i},'Color','cyan')
        hold on
    end
    xline(0,'r')
    title('PhotoDiode Aligned Trials')

    % determine the onset of the trigger
    trigOnsetSamples = [];
    for iTrial = 1:length(triggerSignal.trial)
       
        trigOnsetSample = find(diff(triggerSignal.trial{iTrial})>0.9);
        trigOnsetSamples(iTrial) = trigOnsetSample(1);
       
    end

    %manually put the first trigger at timepoint=0
    for trl = 1:length(dataMain.trial)
        trlData = dataMain.trial{trl};
        trlData(314,:) = circshift(triggerSignal.trial{trl},find(dataMain.time{trl}==0)-trigOnsetSamples(trl)); %shift the trigger data along by N elements (N = number of samples between trigger onset and timepoint 0)
        dataMain.trial{trl} = trlData;
    end
    cfg.channel = 'UPPT001';
    triggerSignal = ft_preprocessing(cfg,dataMain);

    figure;
    for i = 2:length(lightDiodeSignal.time)
        plot(lightDiodeSignal.time{i},lightDiodeSignal.trial{i})
        hold on
        plot(triggerSignal.time{i},triggerSignal.trial{i},'Color','cyan')
        hold on
    end
    xline(0,'r')
    title('Triggers and PhotoDiode Aligned Trials')

    clear lightDiodeSignal visOnset
    
end