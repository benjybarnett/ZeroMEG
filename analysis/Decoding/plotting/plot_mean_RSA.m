function  plot_mean_RSA(cfg, subjects)
    
    %% Set Up Output Path
    outputDir = fullfile(cfg.root,cfg.output_path,'Group');
    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end

    %% Load Data
    load('dot_time.mat');
    time = dot_time;
    all_rho = zeros(length(subjects),length(time));

    for subj =1:length(subjects)
        subject = subjects{subj};
        
        load(fullfile(cfg.root,cfg.output_path,subject,cfg.mRDM_file,'rhos_no_diag.mat'));
        all_rho(subj,:) = rhos;
        clear rhos
    end
    
    %% Calculate Group Average Correlation and 95% CIs
    mean_rho = mean(all_rho,1);
    CIs = CalcCI95(all_rho);
    % Save Group Average
    %save(fullfile(outputDir,[cfg.mRDM_file,'.mat']),'mean_rho','CIs');
    
    %% Plot
    upperCI = mean_rho+CIs;
    lowerCI =mean_rho-CIs;
    x = [time, fliplr(time)];
    
    inBetween = [upperCI, fliplr(lowerCI)];
    fill(x, inBetween,'b', 'FaceColor',cfg.shadecolor,'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time, mean_rho,'Color', cfg.linecolor, 'LineWidth', 1);
    xline(0,'black--');
    yline(0,'black--');
    xlim([time(1) time(end)]);
    ylim(cfg.ylim)
    xlabel('Time (s)')
    ylabel("Dissimilarity Correlation (Kendall's Tau)")

    
end
