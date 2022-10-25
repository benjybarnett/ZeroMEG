function mean_acc = plot_mean_diag(cfg, subjects)

    all_acc = [];
    dir = cfg.root;
    time = load('time_axis.mat');
    time = time.t;
   
    
    for subj =1:length(subjects)
        
        subject = convertCharsToStrings(subjects(subj));
        disp(subject)
        
        try
            load(fullfile(dir,cfg.accDir,subject,cfg.accFile), 'Accuracy');
            disp(fullfile(dir,cfg.accDir,subject,cfg.accFile))

            acc = Accuracy';

        catch
            disp('here')
            disp(fullfile(dir,cfg.accDir,subject,cfg.accFile))
            load(fullfile(dir,cfg.accDir,subject,cfg.accFile), 'acc');
            acc = acc';
        end
        
        
        
        all_acc = [all_acc; acc];
        clear acc Accuracy
    end
    mean_acc = mean(all_acc);
    
    std_dev = std(all_acc);
    CIs = [];
    for i =1:size(all_acc,2)
        
        sd = std_dev(i);
        n = size(all_acc,1);
        
        CIs(i) = 1.96*(sd/sqrt(n));
    end
    
    outputDir = fullfile(cfg.root,'Analysis','MEG','Group',cfg.task);
    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end
    
    save(fullfile(outputDir,cfg.outputName),'mean_acc','CIs');
    
    
    
    curve1 = mean_acc+CIs;
    curve2 =mean_acc-CIs;
    x2 = [time, fliplr(time)];
    
    inBetween = [curve1, fliplr(curve2)];
    
    figure;
   
    fill(x2, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time, mean_acc,'Color', '#0621A6', 'LineWidth', 1);
    hold on;
    yline(0.5,'black--');
    hold on;
    xlim([time(1) time(end)]);
    ylim([0.3 0.8])
    xline(time(end));
    title(cfg.title);
    xlabel('Time (s)')
    ylabel('Accuracy')
    fig = gcf;
    saveas(fig,fullfile(outputDir,[cfg.outputName,'.png']));
    findfigs;
    
end