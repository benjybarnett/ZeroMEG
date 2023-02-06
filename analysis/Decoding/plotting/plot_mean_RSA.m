function  plot_mean_RSA(cfg, subjects)
    
    %% Set Up Output Path
    outputDir = fullfile(cfg.root,cfg.output_path,'Group');
    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end

    %% Load Data
    load('dot_time.mat');
    dot_cut_off = 38; %38th sample
    dot_time = dot_time(dot_cut_off:end);

    load('arabic_time.mat');
    

    for subj =1:length(subjects)
        subject = subjects{subj};
        
        load(fullfile(cfg.root,cfg.output_path,subject,'arabic','rhos_no_diag.mat'));
        all_arabic_rho(subj,:) = arabic_rhos;

        load(fullfile(cfg.root,cfg.output_path,subject,'dots','rhos_no_diag.mat'));
        all_dot_rho(subj,:) = dot_rhos(dot_cut_off:end);
        clear arabic_rhos dot_rhos
    end
    
    %% Calculate Group Average Correlation and 95% CIs
    mean_arabic_rho = mean(all_arabic_rho,1);
    arabic_CIs = CalcCI95(all_arabic_rho);

    mean_dot_rho = mean(all_dot_rho,1);
    dot_CIs = CalcCI95(all_dot_rho);

    % Save Group Average
    %save(fullfile(outputDir,[cfg.mRDM_file,'.mat']),'mean_rho','CIs');
    
    %% Plot
    figure;
    upperCI = mean_arabic_rho+arabic_CIs;
    lowerCI =mean_arabic_rho-arabic_CIs;
    x = [arabic_time, fliplr(arabic_time)];
    
    inBetween = [upperCI, fliplr(lowerCI)];
    fill(x, inBetween,'b', 'FaceColor',cfg.shadecolor{1},'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(arabic_time, mean_arabic_rho,'Color', cfg.linecolor{1}, 'LineWidth', 1);
    xline(0,'black--');
    yline(0,'black--');
    xlim([arabic_time(1) arabic_time(end)]);
    ylim(cfg.ylim)
    xlabel('Time (s)')
    ylabel("Dissimilarity Correlation (Kendall's Tau)")

    hold on;
    
    upperCI = mean_dot_rho+dot_CIs;
    lowerCI =mean_dot_rho-dot_CIs;
    x = [dot_time, fliplr(dot_time)];
    
    inBetween = [upperCI, fliplr(lowerCI)];
    fill(x, inBetween,'b', 'FaceColor',cfg.shadecolor{2},'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(dot_time, mean_dot_rho,'Color', cfg.linecolor{2}, 'LineWidth', 1);

    legend({'','Arabic','','','','Dots'})
    
end
