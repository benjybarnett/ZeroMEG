function plot_multiclass_temp(cfg0, subjects)
% Plot Temporal Generalisation Results for a Multiclass Classifier
% Plots Diagonal and Full Temporal Generalisation Matrix

    time = load("time_axis.mat");
    time = time.t;

    %% Load Classifier Accuracies and Confusion Matrices
    for subj =1:length(subjects)
        subject = subjects{subj};
        disp(subject)

        if strcmp(cfg0.decoding_type,'cross')
            %Accuracy
            num_acc = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_num_acc.mat'));
            det_acc = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_det_acc.mat'));
            %Confusion Matrices
            num_conf_tmp = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_num_confusion.mat'));
            det_conf_tmp = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_det_confusion.mat'));
        elseif strcmp(cfg0.decoding_type,'within')
            %Accuracy
            num_acc = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_num_acc.mat'));
            det_acc = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_det_acc.mat'));   
            %Confusion Matrix
            num_conf_tmp = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_num_confusion.mat'));
            det_conf_tmp = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_det_confusion.mat'));
        else
            warning('Decoding Type Not Recognised');
        end
        
        %Group Accuracies
        num_acc = struct2cell(num_acc); num_acc = num_acc{1};
        det_acc = struct2cell(det_acc); det_acc = det_acc{1};

        all_num_acc(subj,:,:) = num_acc;
        all_det_acc(subj,:,:) = det_acc;
        
        clear num_acc det_acc
        %{

        %Group Confusion Matrices
        num_conf_tmp = struct2cell(num_conf_tmp); num_conf_tmp = num_conf_tmp{1};
        det_conf_tmp = struct2cell(det_conf_tmp); det_conf_tmp = det_conf_tmp{1};

        %Only interested in confusion matrix of diagonal decoding
        %So we extract diagonal from the temporal generalisation matrix
        for trnT = 1:size(num_conf_tmp,1)
            num_conf(trnT,:,:) = squeeze(num_conf_tmp(trnT,:,:,trnT));
        end
        for trnT = 1:size(det_conf_tmp,1)
            det_conf(trnT,:,:) = squeeze(det_conf_tmp(trnT,:,:,trnT));
        end

        all_num_conf(subj,:,:,:) = num_conf;
        all_det_conf(subj,:,:,:) = det_conf;
        %}

        clear num_conf det_conf num_conf_tmp det_conf_tmp
    end
    
    %% Compute Average Accuracies
    mean_num_acc = squeeze(mean(all_num_acc,1));
    mean_det_acc = squeeze(mean(all_det_acc,1));

    %% Compute Average Confusion Matrices
    %{
    mean_num_conf = squeeze(mean(all_num_conf,1));
    mean_det_conf = squeeze(mean(all_det_conf,1));
    %}
    %% Plot Temporal Generalisation Matrices
    if strcmp(cfg0.decoding_type,'cross')
        titles = {'Train on Number, Test on Detection', 'Train on Detection, Test on Number','Train on Number: Diagonal','Train on Detection: Diagonal'};
    else
        titles = {'Number Decoding', 'Detection Decoding','Number Decoding: Diagonal','Detection Decoding: Diagonal'};
    end
    confusion_titles = {'Abs-High','Abs-Low','Pres-Low','Pres-High','Zero','One','Two','Three'};

    %Train on Number, Test on Decoding
    figure('units','normalized','outerposition',[0 0 1 1])
    subplot(3,8,[1.5,3.5]);
    imagesc(time,time,mean_num_acc); axis xy; %colorbar
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    caxis(cfg0.clim)
    colormap('jet')
    title(titles{1});
    
    %Train on Decoding, Test on Number
    subplot(3,8,[5.5,7.925]);
    imagesc(time,time,mean_det_acc); axis xy; colorbar
    xlabel('Train Time (s)'); 
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    caxis(cfg0.clim)
    colormap('jet')
    title(titles{2});
   
    %% Extract Diagonal Decoding
    %Train on Numbers
    all_num_diags = zeros(2,length(time));
    for i = 1:size(all_num_acc,1)
        all_num_diags(i,:) = diag(squeeze(all_num_acc(i,:,:)));
    end

    mean_num_diag = diag(mean_num_acc)';
    num_CIs = CalcCI95(all_num_diags);

    subplot(3,8,[9,12])      
    upperCI = mean_num_diag+num_CIs;
    lowerCI = mean_num_diag-num_CIs; 
    x = [time, fliplr(time)];
    inBetween = [upperCI, fliplr(lowerCI)];
    fill(x, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time,mean_num_diag,'Color', '#0621A6', 'LineWidth', 1);
    yline(0.5,'black--');
    xlim([time(1) time(end)]);
    ylim(cfg0.ylim)
    title(titles{3});
    xline(time(end));
    xlabel('Time (s)')
    ylabel('Accuracy')
    
    %Train on Detection
    all_det_diags = zeros(2,length(time));
    for i = 1:size(all_det_acc,1)
        all_det_diags(i,:) = diag(squeeze(all_det_acc(i,:,:)));
    end
    mean_det_diag = diag(mean_det_acc)';
    det_CIs = CalcCI95(all_det_diags);

    subplot(3,8,[13,16])      
    upperCI = mean_det_diag+det_CIs;
    lowerCI =mean_det_diag-det_CIs; 
    x = [time, fliplr(time)];
    inBetween = [upperCI, fliplr(lowerCI)];
    fill(x, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time,mean_det_diag,'Color', '#0621A6', 'LineWidth', 1);
    yline(0.5,'black--');
    title(titles{4});
    xlim([time(1) time(end)]);
    ylim(cfg0.ylim)
    xline(time(end));
    xlabel('Time (s)')

    %% Plot Confusion Matrices
    %{
    if strcmp(cfg0.decoding_type,'cross')
        confusion_titles = {'Abs-High','Abs-Low','Pres-Low','Pres-High','Zero','One','Two','Three'};
    else
        confusion_titles = {'Zero','One','Two','Three','Abs-High','Abs-Low','Pres-Low','Pres-High'};
    end
    leg = {{'Zero','One','Two','Three'},{'Abs-High','Abs-Low','Pres-Low','Pres-High'}};

    %Train on Number
    num_CIs = CalcCI95(all_num_conf);
    
    t = time(1:10:length(time));
    for true_class = 1:size(mean_num_conf,2)

        %Each loop will be a new plot
        %choose every 10th element for smoothing
        zero = mean_num_conf(1:10:length(time),true_class,1);
        one = mean_num_conf(1:10:length(time),true_class,2);
        two = mean_num_conf(1:10:length(time),true_class,3);
        three = mean_num_conf(1:10:length(time),true_class,4);
        conditions = {zero; one;two; three};

        %f = figure;
        %f.Position = [200 300 250 350];
        subplot(3,8,16+true_class)
        %f.Position = [200 300 250 350];

        curve1 = cell2mat(conditions(true_class))'+num_CIs(1:10:length(time));
        curve2 =cell2mat(conditions(true_class))'-num_CIs(1:10:length(time));
        x2 = [t, fliplr(t)];
        inBetween = [curve1, fliplr(curve2)];

        ci_colours = {[0, 0.4470, 0.7410],[0.8500, 0.3250, 0.0980],	[0.9290, 0.6940, 0.1250],[0.4940, 0.1840, 0.5560]};		
        f = fill(x2, inBetween,cell2mat(ci_colours(true_class)),'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
        f.Annotation.LegendInformation.IconDisplayStyle = 'off';
        hold on;
        chance = yline(0.25,'--','LineWidth', 1.4,'Color','black');
        chance.Annotation.LegendInformation.IconDisplayStyle = 'off';
        
        plot(t,zero,'Color',cell2mat(ci_colours(1)),'LineWidth',1.2);      
        plot(t,one,'Color',cell2mat(ci_colours(2)),'LineWidth',1.2);    
        plot(t,two,'Color',cell2mat(ci_colours(3)),'LineWidth',1.2); 
        plot(t,three,'Color',cell2mat(ci_colours(4)),'LineWidth',1.2);
      
        xlim([min(time),max(time)])
        ylim([0 0.8])
        
        if true_class == 1
            [pos,hobj,~,~] = legend(leg{1});
            hl = findobj(hobj,'type','line');
            set(hl,'LineWidth',3);
            ht = findobj(hobj,'type','text');
            set(ht,'FontSize',6);
            set(ht,'FontName','Arial');
            %set(pos,'position',[0.705 0.175 0.1 0.1])
            ylabel('Proportion Classified','FontName','Arial')
        end
       
        xlabel('Time (seconds)','FontName','Arial')
        title(confusion_titles(true_class),'FontName','Arial')
    end

    %Train on Detection
    det_CIs = CalcCI95(all_det_conf);

    for true_class = 1:size(mean_det_conf,2)

        %Each loop will be a new plot
        %choose every 10th element for smoothing
        zero = mean_det_conf(1:10:length(time),true_class,1);
        one = mean_det_conf(1:10:length(time),true_class,2);
        two = mean_det_conf(1:10:length(time),true_class,3);
        three = mean_det_conf(1:10:length(time),true_class,4);
        conditions = {zero; one;two; three};

        %f = figure;
        %f.Position = [200 300 250 350];
        f = subplot(3,8,20+true_class);
        %f.Position = [200 300 250 350];
        
        curve1 = cell2mat(conditions(true_class))'+det_CIs(1:10:length(time));
        curve2 =cell2mat(conditions(true_class))'-det_CIs(1:10:length(time));
        x2 = [t, fliplr(t)];
        inBetween = [curve1, fliplr(curve2)];
        
        ci_colours = {[0, 0.4470, 0.7410],[0.8500, 0.3250, 0.0980],	[0.9290, 0.6940, 0.1250],[0.4940, 0.1840, 0.5560]};		
        f = fill(x2, inBetween,cell2mat(ci_colours(true_class)),'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
        f.Annotation.LegendInformation.IconDisplayStyle = 'off';
        hold on;
        chance = yline(0.25,'--','LineWidth', 1.4,'Color','black');
        chance.Annotation.LegendInformation.IconDisplayStyle = 'off';
        
        plot(t,zero,'Color',cell2mat(ci_colours(1)),'LineWidth',1.2);      
        plot(t,one,'Color',cell2mat(ci_colours(2)),'LineWidth',1.2);    
        plot(t,two,'Color',cell2mat(ci_colours(3)),'LineWidth',1.2); 
        plot(t,three,'Color',cell2mat(ci_colours(4)),'LineWidth',1.2);
      
        xlim([min(time),max(time)])
        ylim([0 0.8])
        if true_class == 1
            [pos,hobj,~,~] = legend(leg{2});
            hl = findobj(hobj,'type','line');
            set(hl,'LineWidth',3);
            ht = findobj(hobj,'type','text');
            set(ht,'FontSize',6);
            set(ht,'FontName','Arial');
            %set(pos,'position',[0.705 0.175 0.1 0.1])
            ylabel('Proportion Classified','FontName','Arial')
        end
       
        xlabel('Time (seconds)','FontName','Arial')
        title(confusion_titles(true_class+4),'FontName','Arial')   
    end
    %}
    %% Save
    outputDir = fullfile(cfg0.root,cfg0.output_path,'Group');
    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end
    
    fig = gcf;
    saveas(fig,fullfile(outputDir,[cfg0.figName,'.png']));
    save(fullfile(outputDir,cfg0.accFile),'mean_num_acc','mean_num_diag',"mean_det_acc",'mean_det_diag');

  
end