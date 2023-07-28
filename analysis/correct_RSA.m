function [pVals] = correct_RSA(cfg0,subjects)

    outputDir = fullfile(cfg0.root,cfg0.output_path,cfg0.mRDM_file,'Group');
    if ~exist(outputDir,'dir'); mkdir(outputDir); end
    
    
    all_rho = [];
    time = load('arabic_time');
    time = time.arabic_time;
    
    for subj =1:length(subjects)
    
        subject = subjects{subj};
        disp(subject)
    
        load(fullfile(cfg0.root,cfg0.output_path,cfg0.mRDM_file,subject,cfg0.mRDM_file,'rhos_no_diag.mat'));
        all_rho = [all_rho; rhos];
    
        clear rhos
    end
    
    cfgS = [];cfgS.paired = false;cfgS.tail= 'one'; cfgS.indiv_pval = 0.05; cfgS.cluster_pval = 0.05;
    disp(size(all_rho))
    
    pVals= cluster_based_permutationND(all_rho,0,cfgS);
    save(fullfile(outputDir,['pVals_',cfg0.mRDM_file]),'pVals')
    
    disp(unique(pVals))

    %plot
    if cfg0.plot

        %diagonals
        %plot diagonal of accuracy matrix

        mean_rho = mean(all_rho,1);

        std_dev = std(all_rho,1);
        CIs = [];
        for i =1:size(all_rho,2)
            sd = std_dev(i);
            n = size(all_rho,1);

            CIs(i) = 1.96*(sd/sqrt(n));
        end

        curve1 = mean_rho+CIs;
        curve2 =mean_rho-CIs;
        x2 = [time, fliplr(time)];


        inBetween = [curve1, fliplr(curve2)];
        figure;

        fill(x2, inBetween,'b', 'FaceColor',cfg0.shadecolor{1},'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
        hold on;
        plot(time, mean_rho,'Color', cfg0.linecolor{1}, 'LineWidth', 1);
        xline(0,'black--');
        yline(0,'black--');
        xlim([time(1) time(end)]);
        ylim(cfg0.ylim)
        %xticks([0 0.5 1 1.5]);
        xticks([-0.4 0 0.4 0.8 1.2 1.6]);xticklabels({-0.4 0 0.4 0.8 1.2 1.6})
        xlabel('Time (s)')
        ylabel("Dissimilarity Correlation (Kendall's Tau)")
        xline(time(end));
        x1=NaN;x1s=[];x2s = [];
        %sig points on diag
        sigidxs = find(pVals ~= 1);
        if all(diff(sigidxs)) %if all part of one cluster
            line([time(sigidxs(1)),time(sigidxs(end))],[cfg0.sig_height,cfg0.sig_height],'Color',cfg0.shadecolor{1},'LineWidth',2)
        else %if multiple clusters
            clus_beg_idxs = [1;find(diff(sigidxs)>1)+1]; 
            clus_end_idxs = [clus_beg_idxs(2:end) - 1;length(sigidxs)];
            for c = 1:length(clus_beg_idxs)
                line([time(sigidxs(clus_beg_idxs(c))),time(sigidxs(clus_end_idxs(c)))],[cfg0.sig_height,cfg0.sig_height],'Color',cfg0.shadecolor{1},'LineWidth',2)
            end
        end
end
