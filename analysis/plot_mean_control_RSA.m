function  plot_mean_control_RSA(cfg, subjects)
    
    %% Set Up Output Path
    outputDir = fullfile(cfg.root,cfg.output_path,'Group');
    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end

    %% Load Data
    load('dot_time.mat');
    %{
    dot_cut_off = 38; %38th sample
    dot_time = dot_time(dot_cut_off:end);
    %}

    load('arabic_time.mat');
    

    for subj =1:length(subjects)
        subject = subjects{subj};
        rhos = load(fullfile(cfg.root,cfg.output_path,subject,cfg.mRDM_file,'rhos_no_diag.mat'));
        rhos = struct2cell(rhos);rhos = rhos{1};
        all_rhos(subj,:) = rhos;

        clear rhos
    end
    
    %% Calculate Group Average Correlation and 95% CIs
    
    mean_rho = mean(all_rhos,1);
    CIs = CalcCI95(all_rhos);


    % Save Group Average
    %save(fullfile(outputDir,[cfg.mRDM_file,'.mat']),'mean_rho','CIs');
    
    %% Plot
    figure;
    if contains(cfg.task,'arabic')
        time = arabic_time;
    else
        time = dot_time;
    end
        
        
    upperCI = mean_rho+CIs;
    lowerCI =mean_rho-CIs;
    x = [time, fliplr(time)];
    
    inBetween = [upperCI, fliplr(lowerCI)];
    fill(x, inBetween,'b', 'FaceColor',cfg.shadecolor{1},'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time, mean_rho,'Color', cfg.linecolor{1}, 'LineWidth', 1);
    xline(0,'black--');
    yline(0,'black--');
    xlim([time(1) time(end)]);
    ylim(cfg.ylim)
    title(cfg.title)
    xlabel('Time (s)')
    ylabel("Dissimilarity Correlation (Kendall's Tau)")
end
    

