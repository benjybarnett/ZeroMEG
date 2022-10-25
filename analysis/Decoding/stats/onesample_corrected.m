function onesample_corrected(cfg,subjects)
% Run a one-sample test on accuracy scores while correcting
% the temporal generlisation matrices for multiple comparisons.
% Plots the matrix and diagonal with significant clusters outlined.

outputDir = fullfile(cfg.root,cfg.output_path,'Group','Stats');
if ~exist(outputDir,'dir')
    mkdir(outputDir)
end
    
time = load('time_axis.mat');
time = time.t;

num_acc = zeros(length(subjects),length(time),length(time));
det_acc=zeros(length(subjects),length(time),length(time));

%% Load Accuracy Matrices
for subj =1:length(subjects)

   subject = subjects{subj};
   disp(subject)
   
       
   num_acc = load(fullfile(cfg.root,cfg.output_path,subject,cfg.resultsFile{1}));
   num_acc = struct2cell(num_acc); num_acc = num_acc{1};
    
   det_acc = load(fullfile(cfg.root,cfg.output_path,subject,cfg.resultsFile{2}));
   det_acc = struct2cell(det_acc); det_acc = det_acc{1};
    
   all_num_acc(subj,:,:) = num_acc;
   all_det_acc(subj,:,:) = det_acc;
   
end

%% Run Correction Procedure
cfgS = [];cfgS.paired = false;cfgS.tail= 'one'; cfgS.indiv_pval = 0.05; cfgS.cluster_pval = 0.05;

fprintf('Correcting Data with %d subjects with %d train and %d test time-points each \n',size(all_num_acc,1),size(all_num_acc,3),size(all_num_acc,2));
pVals_onesamp_num = cluster_based_permutationND(all_num_acc,0.25,cfgS);
save(fullfile(outputDir,'pVals_train_num.mat'),'pVals_onesamp_num')

fprintf('Correcting Data with %d subjects with %d train and %d test time-points each \n',size(all_det_acc,1),size(all_det_acc,3),size(all_det_acc,2));
pVals_onesamp_det = cluster_based_permutationND(all_det_acc,0.25,cfgS);
save(fullfile(outputDir,'pVals_train_det.mat'),'pVals_onesamp_det')


%% Plotting
if cfg.plot
    if strcmp(cfg.decoding_type,'cross')
        titles = {'Train on Number, Test on Detection','Train on Detection, Test on Number','Train on Numbers: Diagonal','Train on Detection: Diagonal'};
    else
        titles = {'Number Decoding','Detection Decoding','Number Decoding: Diagonal','Detection Diagonal: Diagonal'};
    end

    %Create Mask of Significant P Values
    num_mask = pVals_onesamp_num;
    colormap jet;
    imAlpha = ones(size(num_mask));
    imAlpha(num_mask==1)=0.25;

    %Calculate Mean Accuracy
    mean_num_acc = squeeze(mean(all_num_acc,1));

    %plot
    figure('units','normalized','outerposition',[0 0 1 1])
    subplot(2,2,1)
    imagesc(time,time,mean_num_acc,'AlphaData',imAlpha); axis xy;
    xticks([0 0.5 1 1.5 2]);xticklabels({0 ,0.5 ,1, 1.5, 2});yticks([0 0.5 1 1.5 ]);yticklabels({0 ,0.5 ,1, 1.5 });
    colorbar;
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'black'); hold on; plot(xlim,[0 0],'black');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    caxis(cfg.clim)
    colormap('jet')
    hold on;
    title(titles{1});
    

    %Train on Detection, Test on Number
    
    %Create Mask of Significant P Values
    det_mask = pVals_onesamp_det;
    colormap jet;
    imAlpha = ones(size(det_mask));
    imAlpha(det_mask==1)=0.25;

    %Calculate Mean Accuracy
    mean_det_acc = squeeze(mean(all_det_acc,1));

    %plot
    subplot(2,2,2)
    imagesc(time,time,mean_det_acc,'AlphaData',imAlpha); axis xy;
    xticks([0 0.5 1 1.5 2]);xticklabels({0 ,0.5 ,1, 1.5, 2});yticks([0 0.5 1 1.5 ]);yticklabels({0 ,0.5 ,1, 1.5 });
    colorbar;
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'black'); hold on; plot(xlim,[0 0],'black');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    caxis(cfg.clim)
    colormap('jet')
    hold on;
    title(titles{2});
    
    %% Diagonal Plots
    num_subjects = size(all_num_acc,1);
    all_diags = zeros(num_subjects,length(time));

    %Train on Numbers, Test on Detection

    for i = 1:num_subjects
        all_diags(i,:) = diag(squeeze(all_num_acc(i,:,:)));
    end

    %Mean and CI
    mean_num_acc = squeeze(mean(all_diags,1));
    CIs = CalcCI95(all_diags);
    
    %Plotting
    subplot(2,2,3);
    curve1 = mean_num_acc+CIs;
    curve2 =mean_num_acc-CIs;    
    x2 = [time, fliplr(time)];
    inBetween = [curve1, fliplr(curve2)];
   
   
    fill(x2, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time,mean_num_acc,'Color', '#0621A6', 'LineWidth', 1);
    yline(0.25,'black--');
    xlim([time(1) time(end)]);
    ylim(cfg.ylim)
    xline(time(end));
    xlabel('Time (s)')
    ylabel('Accuracy')
    title(titles{3})
    hold on;

    % Add markers for significant clusters 
    x1 = NaN;
    x1s =[];
    diagp = diag(pVals_onesamp_num); %p values on diagonal
    for h = 1:length(diagp)
           if diagp(h) ~= 1 && isnan(x1)
               x1 = h;
               x1s = [x1s x1];
               continue;
           end         
           if diagp(h) == 1 && ~isnan(x1)
               x2 = h-1;
               line([time(x1),time(x2)], [0.45,0.45],'Color','black');
               hold on;
               x1 = NaN;
               continue
           end           
    end
    if ~ isnan(x1)
        line([time(x1),time(end)], [0.45,0.45],'Color','black');
    end
        
    %Train on Detection, Test on Number
    for i = 1:num_subjects
        all_diags(i,:) = diag(squeeze(all_det_acc(i,:,:)));
    end

    %Mean and CI
    mean_det_acc = squeeze(mean(all_diags,1));
    CIs = CalcCI95(all_diags);
    
    %Plotting
    subplot(2,2,4);
    curve1 = mean_det_acc+CIs;
    curve2 =mean_det_acc-CIs;    
    x2 = [time, fliplr(time)];
    inBetween = [curve1, fliplr(curve2)];
   
   
    fill(x2, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time,mean_det_acc,'Color', '#0621A6', 'LineWidth', 1);
    yline(0.25,'black--');
    xlim([time(1) time(end)]);
    ylim(cfg.ylim)
    xline(time(end));
    xlabel('Time (s)')
    ylabel('Accuracy')
    title(titles{4})
    hold on;

    % Add markers for significant clusters 
    x1 = NaN;
    x1s =[];
    diagp = diag(pVals_onesamp_det); %p values on diagonal
    for h = 1:length(diagp)
           if diagp(h) ~= 1 && isnan(x1)
               x1 = h;
               x1s = [x1s x1];
               continue;
           end         
           if diagp(h) == 1 && ~isnan(x1)
               x2 = h-1;
               line([time(x1),time(x2)], [0.45,0.45],'Color','black');
               hold on;
               x1 = NaN;
               continue
           end           
    end
    if ~ isnan(x1)
        line([time(x1),time(end)], [0.45,0.45],'Color','black');
    end
        
end

%% Save Plots
fig = gcf;
saveas(fig,fullfile(outputDir,[cfg.figName,'.png']));


end
    