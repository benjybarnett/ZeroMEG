function plot_multiclass_temp(cfg0, subjects)
% Plot Temporal Generalisation Results for a Multiclass Classifier
% Plots Diagonal and Full Temporal Generalisation Matrix

    arabic_time = load("arabic_time.mat");
    arabic_time = arabic_time.arabic_time;

    dot_time = load("dot_time.mat");
    dot_time = dot_time.dot_time;
    %% Load Classifier Accuracies and Confusion Matrices
    for subj =1:length(subjects)
        subject = subjects{subj};
        disp(subject)

        if strcmp(cfg0.decoding_type,'cross')
            dot_time = arabic_time;
            %Accuracy
            arabic_acc = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_arabic_acc.mat'));
            dot_acc = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_dot_acc.mat'));
            %Confusion Matrices
            arabic_conf_tmp = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_arabic_conf.mat'));
            dot_conf_tmp = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_dot_conf.mat'));
        elseif strcmp(cfg0.decoding_type,'within')
            %Accuracy
            arabic_acc = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_arabic_acc.mat'));
            dot_acc = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_dot_acc.mat'));   
            %Confusion Matrix
            arabic_conf_tmp = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_arabic_conf.mat'));
            dot_conf_tmp = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_dot_conf.mat'));
        else
            warning('Decoding Type Not Recognised');
        end
        
        %Group Accuracies
        arabic_acc = struct2cell(arabic_acc); arabic_acc = arabic_acc{1};
        dot_acc = struct2cell(dot_acc); dot_acc = dot_acc{1};

        all_arabic_acc(subj,:,:) = arabic_acc;
        all_dot_acc(subj,:,:) = dot_acc;
        
        clear arabic_acc dot_acc
        

        %Group Confusion Matrices
        arabic_conf_tmp = struct2cell(arabic_conf_tmp); arabic_conf_tmp = arabic_conf_tmp{1};
        dot_conf_tmp = struct2cell(dot_conf_tmp); dot_conf_tmp = dot_conf_tmp{1};

        %Only interested in confusion matrix of diagonal decoding
        %So we extract diagonal from the temporal generalisation matrix
        for trnT = 1:size(arabic_conf_tmp,1)
            arabic_conf(trnT,:,:) = squeeze(arabic_conf_tmp(trnT,:,:,trnT));
        end
        for trnT = 1:size(dot_conf_tmp,1)
            dot_conf(trnT,:,:) = squeeze(dot_conf_tmp(trnT,:,:,trnT));
        end

        all_arabic_conf(subj,:,:,:) = arabic_conf;
        all_dot_conf(subj,:,:,:) = dot_conf;
        

        clear arabic_conf dot_conf arabic_conf_tmp dot_conf_tmp
    end
    
    %% Compute Average Accuracies
    mean_arabic_acc = squeeze(mean(all_arabic_acc,1));
    mean_dot_acc = squeeze(mean(all_dot_acc,1));

    %% Compute Average Confusion Matrices
    
    mean_arabic_conf = squeeze(mean(all_arabic_conf,1));
    mean_dot_conf = squeeze(mean(all_dot_conf,1));
    
    %% Plot Temporal Generalisation Matrices
    if strcmp(cfg0.decoding_type,'cross')
        titles = {'Train on Number, Test on Detection', 'Train on Detection, Test on Number','Train on Number: Diagonal','Train on Detection: Diagonal'};
    else
        titles = {'Arabic Decoding', 'Dot Decoding','Arabic Decoding: Diagonal','Dot Decoding: Diagonal'};
    end
    confusion_titles = {'Abs-High','Abs-Low','Pres-Low','Pres-High','Zero','One','Two','Three'};

    %Train on Number, Test on Decoding
    figure('units','normalized','outerposition',[0 0 1 1])
    subplot(2,2,1);
    imagesc(arabic_time,arabic_time,mean_arabic_acc); axis xy; %colorbar
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    caxis(cfg0.clim)
    colormap('jet')
    title(titles{1});
    
    %Train on Decoding, Test on Number
    subplot(2,2,2);
    imagesc(dot_time,dot_time,mean_dot_acc); axis xy; colorbar
    xlabel('Train Time (s)'); 
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    caxis(cfg0.clim)
    colormap('jet')
    title(titles{2});
   
    %% Extract Diagonal Decoding
    %Train on Numbers
    all_arabic_diags = zeros(2,length(arabic_time));
    for i = 1:size(all_arabic_acc,1)
        all_arabic_diags(i,:) = diag(squeeze(all_arabic_acc(i,:,:)));
    end

    mean_arabic_diag = diag(mean_arabic_acc)';
    arabic_CIs = CalcCI95(all_arabic_diags);

    subplot(2,2,3)      
    upperCI = mean_arabic_diag+arabic_CIs;
    lowerCI = mean_arabic_diag-arabic_CIs; 
    x = [arabic_time, fliplr(arabic_time)];
    inBetween = [upperCI, fliplr(lowerCI)];
    fill(x, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(arabic_time,mean_arabic_diag,'Color', '#0621A6', 'LineWidth', 1);
    xlim([arabic_time(1) arabic_time(end)]);
    ylim(cfg0.ylim)
    title(titles{3});
    xline(arabic_time(end));
    yline(1/6,'--');
    xlabel('Time (s)')
    ylabel('Accuracy')
    
    %Train on Detection
    all_dot_diags = zeros(2,length(dot_time));
    for i = 1:size(all_dot_acc,1)
        all_dot_diags(i,:) = diag(squeeze(all_dot_acc(i,:,:)));
    end
    mean_dot_diag = diag(mean_dot_acc)';
    dot_CIs = CalcCI95(all_dot_diags);

    subplot(2,2,4)      
    upperCI = mean_dot_diag+dot_CIs;
    lowerCI =mean_dot_diag-dot_CIs; 
    x = [dot_time, fliplr(dot_time)];
    inBetween = [upperCI, fliplr(lowerCI)];
    fill(x, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(dot_time,mean_dot_diag,'Color', '#0621A6', 'LineWidth', 1);
    title(titles{4});
    xlim([dot_time(1) dot_time(end)]);
    ylim(cfg0.ylim)
    xline(dot_time(end));
    yline(1/6,'--');
    xlabel('Time (s)')

    %% Plot Confusion Matrices
    
    if strcmp(cfg0.decoding_type,'cross')
        confusion_titles = {'Zero','One','Two','Three','Four','Five','Zero','One','Two','Three','Four','Five'};
    else
        confusion_titles = {'A-Zero','A-One','A-Two','A-Three','A-Four','A-Five','D-Zero','D-One','D-Two','D-Three','D-Four','D-Five'};
    end
    leg = {{'Zero','One','Two','Three','Four','Five'},{'Zero','One','Two','Three','Four','Five'}};

    %Train on Number
    arabic_CIs = CalcCI95(all_arabic_conf);
    figure;
    t = arabic_time(1:10:length(arabic_time));
    for true_class = 1:size(mean_arabic_conf,2)
        %Each loop will be a new plot
        %choose every 10th element for smoothing
        zero = mean_arabic_conf(1:10:length(arabic_time),true_class,1);
        one = mean_arabic_conf(1:10:length(arabic_time),true_class,2);
        two = mean_arabic_conf(1:10:length(arabic_time),true_class,3);
        three = mean_arabic_conf(1:10:length(arabic_time),true_class,4);
        four = mean_arabic_conf(1:10:length(arabic_time),true_class,5);
        five = mean_arabic_conf(1:10:length(arabic_time),true_class,6);
        conditions = {zero; one;two; three;four;five};

        %f = figure;
        %f.Position = [200 300 250 350];
        subplot(2,6,true_class)
        %f.Position = [200 300 250 350];

        curve1 = cell2mat(conditions(true_class))'+arabic_CIs(1:10:length(arabic_time));
        curve2 =cell2mat(conditions(true_class))'-arabic_CIs(1:10:length(arabic_time));
        x2 = [t, fliplr(t)];
        inBetween = [curve1, fliplr(curve2)];

        ci_colours = {[1, 0, 0],[1, 165/255, 0],	[50/255, 205/255, 50/255],[0, 1, 1],[0, 0, 1],[1,0,1]};		

        f = fill(x2, inBetween,cell2mat(ci_colours(true_class)),'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
        f.Annotation.LegendInformation.IconDisplayStyle = 'off';
        hold on;
        chance = yline(1/6,'--','LineWidth', 1.4,'Color','black');
        chance.Annotation.LegendInformation.IconDisplayStyle = 'off';
        
        plot(t,zero,'Color',cell2mat(ci_colours(1)),'LineWidth',1.2);      
        plot(t,one,'Color',cell2mat(ci_colours(2)),'LineWidth',1.2);    
        plot(t,two,'Color',cell2mat(ci_colours(3)),'LineWidth',1.2); 
        plot(t,three,'Color',cell2mat(ci_colours(4)),'LineWidth',1.2);
        plot(t,four,'Color',cell2mat(ci_colours(5)),'LineWidth',1.2);
        plot(t,five,'Color',cell2mat(ci_colours(6)),'LineWidth',1.2);
        
        xlim([min(arabic_time),max(arabic_time)])
        ylim([0 0.8])
        if true_class == 1
            [pos,hobj,~,~] = legend(leg{1});
            hl = findobj(hobj,'type','line');
            set(hl,'LineWidth',3);
            ht = findobj(hobj,'type','text');
            set(ht,'FontSize',6);
            set(ht,'FontName','Arial');
            set(pos,'Location','best')
            ylabel('Proportion Classified','FontName','Arial')
        end
       
        xlabel('Time (seconds)','FontName','Arial')
        title(confusion_titles(true_class),'FontName','Arial')
    end

    %Train on Dots
    dot_CIs = CalcCI95(all_dot_conf);
    t = dot_time(1:10:length(dot_time));

    for true_class = 1:size(mean_dot_conf,2)

        %Each loop will be a new plot
        %choose every 10th element for smoothing
        zero = mean_dot_conf(1:10:length(dot_time),true_class,1);
        one = mean_dot_conf(1:10:length(dot_time),true_class,2);
        two = mean_dot_conf(1:10:length(dot_time),true_class,3);
        three = mean_dot_conf(1:10:length(dot_time),true_class,4);
        four = mean_dot_conf(1:10:length(dot_time),true_class,5);
        five = mean_dot_conf(1:10:length(dot_time),true_class,6);

        conditions = {zero; one;two; three;four;five};

        %f = figure;
        %f.Position = [200 300 250 350];
        f = subplot(2,6,6+true_class);
        %f.Position = [200 300 250 350];
        
        curve1 = cell2mat(conditions(true_class))'+dot_CIs(1:10:length(dot_time));
        curve2 =cell2mat(conditions(true_class))'-dot_CIs(1:10:length(dot_time));
        x2 = [t, fliplr(t)];
        inBetween = [curve1, fliplr(curve2)];
        
        ci_colours = {[1, 0, 0],[1, 165/255, 0],[50/255, 205/255, 50/255],[0, 1, 1],[0, 0, 1],[1,0,1]};		
        f = fill(x2, inBetween,cell2mat(ci_colours(true_class)),'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
        f.Annotation.LegendInformation.IconDisplayStyle = 'off';
        hold on;
        chance = yline(1/6,'--','LineWidth', 1.4,'Color','black');
        chance.Annotation.LegendInformation.IconDisplayStyle = 'off';
        
        plot(t,zero,'Color',cell2mat(ci_colours(1)),'LineWidth',1.2);      
        plot(t,one,'Color',cell2mat(ci_colours(2)),'LineWidth',1.2);    
        plot(t,two,'Color',cell2mat(ci_colours(3)),'LineWidth',1.2); 
        plot(t,three,'Color',cell2mat(ci_colours(4)),'LineWidth',1.2);
        plot(t,four,'Color',cell2mat(ci_colours(5)),'LineWidth',1.2);
        plot(t,five,'Color',cell2mat(ci_colours(6)),'LineWidth',1.2);
      
        xlim([min(dot_time),max(dot_time)])
        ylim([0 0.8])

        if true_class == 1
            [pos,hobj,~,~] = legend(leg{2});
            hl = findobj(hobj,'type','line');
            set(hl,'LineWidth',3);
            ht = findobj(hobj,'type','text');
            set(ht,'FontSize',6);
            set(ht,'FontName','Arial');
            set(pos,'Location','best')
            ylabel('Proportion Classified','FontName','Arial')
        end
       
        xlabel('Time (seconds)','FontName','Arial')
        title(confusion_titles(true_class+6),'FontName','Arial')   
    end
    
    %% Save
    outputDir = fullfile(cfg0.root,cfg0.output_path,'Group');
    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end
    
    fig = gcf;
    saveas(fig,fullfile(outputDir,[cfg0.figName,'.png']));
    save(fullfile(outputDir,cfg0.accFile),'mean_arabic_acc','mean_arabic_diag',"mean_dot_acc",'mean_dot_diag');


    %% Plot accuracies when removing each numerosity systematically
    if cfg0.sysRemove
        for subj =1:length(subjects)
            subject = subjects{subj};
            disp(subject)
    
            if strcmp(cfg0.decoding_type,'cross')
                dot_time = arabic_time;
                %Accuracy
                arabic_acc_no0 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_arabic_acc_no_0.mat'));
                dot_acc_no0 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_dot_acc_no_0.mat'));
                arabic_acc_no1 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_arabic_acc_no_1.mat'));
                dot_acc_no1 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_dot_acc_no_1.mat'));
                arabic_acc_no2 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_arabic_acc_no_2.mat'));
                dot_acc_no2 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_dot_acc_no_2.mat'));
                arabic_acc_no3 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_arabic_acc_no_3.mat'));
                dot_acc_no3 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_dot_acc_no_3.mat'));
                arabic_acc_no4 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_arabic_acc_no_4.mat'));
                dot_acc_no4 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_dot_acc_no_4.mat'));
                arabic_acc_no5 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_arabic_acc_no_5.mat'));
                dot_acc_no5 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_dot_acc_no_5.mat'));
                arabic_acc_no05 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_arabic_acc_no_6.mat'));
                dot_acc_no05 = load(fullfile(cfg0.root,cfg0.output_path,subject,'cross_dot_acc_no_6.mat'));
            elseif strcmp(cfg0.decoding_type,'within')
                continue;
            else
                warning('Decoding Type Not Recognised');
            end
            
            %Group Accuracies
            arabic_acc_no0 = struct2cell(arabic_acc_no0); arabic_acc_no0 = arabic_acc_no0{1};
            dot_acc_no0 = struct2cell(dot_acc_no0); dot_acc_no0 = dot_acc_no0{1};
            all_arabic_acc_no0(subj,:,:) = diag(arabic_acc_no0);
            all_dot_acc_no0(subj,:,:) = diag(dot_acc_no0);
            
            arabic_acc_no1 = struct2cell(arabic_acc_no1); arabic_acc_no1 = arabic_acc_no1{1};
            dot_acc_no1 = struct2cell(dot_acc_no1); dot_acc_no1 = dot_acc_no1{1};
            all_arabic_acc_no1(subj,:,:) = diag(arabic_acc_no1);
            all_dot_acc_no1(subj,:,:) = diag(dot_acc_no1);
    
            arabic_acc_no2 = struct2cell(arabic_acc_no2); arabic_acc_no2 = arabic_acc_no2{1};
            dot_acc_no2 = struct2cell(dot_acc_no2); dot_acc_no2 = dot_acc_no2{1};
            all_arabic_acc_no2(subj,:,:) = diag(arabic_acc_no2);
            all_dot_acc_no2(subj,:,:) = diag(dot_acc_no2);
            
            arabic_acc_no3 = struct2cell(arabic_acc_no3); arabic_acc_no3 = arabic_acc_no3{1};
            dot_acc_no3 = struct2cell(dot_acc_no3); dot_acc_no3 = dot_acc_no3{1};
            all_arabic_acc_no3(subj,:,:) = diag(arabic_acc_no3);
            all_dot_acc_no3(subj,:,:) = diag(dot_acc_no3);
            
            arabic_acc_no4 = struct2cell(arabic_acc_no4); arabic_acc_no4 = arabic_acc_no4{1};
            dot_acc_no4 = struct2cell(dot_acc_no4); dot_acc_no4 = dot_acc_no4{1};
            all_arabic_acc_no4(subj,:,:) = diag(arabic_acc_no4);
            all_dot_acc_no4(subj,:,:) = diag(dot_acc_no4);
    
            arabic_acc_no5 = struct2cell(arabic_acc_no5); arabic_acc_no5 = arabic_acc_no5{1};
            dot_acc_no5 = struct2cell(dot_acc_no5); dot_acc_no5 = dot_acc_no5{1};
            all_arabic_acc_no5(subj,:,:) = diag(arabic_acc_no5);
            all_dot_acc_no5(subj,:,:) = diag(dot_acc_no5);

            %no 0 and 5
            arabic_acc_no05 = struct2cell(arabic_acc_no05); arabic_acc_no05 = arabic_acc_no05{1};
            dot_acc_no05 = struct2cell(dot_acc_no05); dot_acc_no05 = dot_acc_no05{1};
            all_arabic_acc_no05(subj,:,:) = diag(arabic_acc_no05);
            all_dot_acc_no05(subj,:,:) = diag(dot_acc_no05);
    
    
            clear arabic_conf dot_conf arabic_conf_tmp dot_conf_tmp
        end
        
        %% Compute Average Accuracies
        mean_arabic_acc_no0 = squeeze(mean(all_arabic_acc_no0,1));
        mean_dot_acc_no0 = squeeze(mean(all_dot_acc_no0,1));
        arabicCI_no0 = CalcCI95(all_arabic_acc_no0);
        dotCI_no0 = CalcCI95(all_dot_acc_no0);

       % clear all_arabic_acc_no0 all_dot_acc_no0

        mean_arabic_acc_no1 = squeeze(mean(all_arabic_acc_no1,1));
        mean_dot_acc_no1 = squeeze(mean(all_dot_acc_no1,1));
        arabicCI_no1 = CalcCI95(all_arabic_acc_no1);
        dotCI_no1 = CalcCI95(all_dot_acc_no1);

        clear all_arabic_acc_no1 all_dot_acc_no1

        mean_arabic_acc_no2 = squeeze(mean(all_arabic_acc_no2,1));
        mean_dot_acc_no2 = squeeze(mean(all_dot_acc_no2,1));
        arabicCI_no2 = CalcCI95(all_arabic_acc_no2);
        dotCI_no2 = CalcCI95(all_dot_acc_no2);

        clear all_arabic_acc_no2 all_dot_acc_no2

        mean_arabic_acc_no3 = squeeze(mean(all_arabic_acc_no3,1));
        mean_dot_acc_no3 = squeeze(mean(all_dot_acc_no3,1));
        arabicCI_no3 = CalcCI95(all_arabic_acc_no3);
        dotCI_no3 = CalcCI95(all_dot_acc_no3);

        clear all_arabic_acc_no3 all_dot_acc_no3

        mean_arabic_acc_no4 = squeeze(mean(all_arabic_acc_no4,1));
        mean_dot_acc_no4 = squeeze(mean(all_dot_acc_no4,1));
        arabicCI_no4 = CalcCI95(all_arabic_acc_no4);
        dotCI_no4 = CalcCI95(all_dot_acc_no4);

        clear all_arabic_acc_no4 all_dot_acc_no4

        mean_arabic_acc_no5 = squeeze(mean(all_arabic_acc_no5,1));
        mean_dot_acc_no5 = squeeze(mean(all_dot_acc_no5,1));
        arabicCI_no5 = CalcCI95(all_arabic_acc_no5);
        dotCI_no5 = CalcCI95(all_dot_acc_no5);

        clear all_arabic_acc_no5 all_dot_acc_no5

        mean_arabic_acc_no05 = squeeze(mean(all_arabic_acc_no05,1));
        mean_dot_acc_no05 = squeeze(mean(all_dot_acc_no05,1));
        arabicCI_no05 = CalcCI95(all_arabic_acc_no05);
        dotCI_no05 = CalcCI95(all_dot_acc_no05);

        clear all_arabic_acc_no05 all_dot_acc_no05

        all_arabic = {mean_arabic_acc_no0; mean_arabic_acc_no1; mean_arabic_acc_no2; mean_arabic_acc_no3;mean_arabic_acc_no4;mean_arabic_acc_no5;mean_arabic_acc_no05};
        all_dots = {mean_dot_acc_no0; mean_dot_acc_no1; mean_dot_acc_no2; mean_dot_acc_no3;mean_dot_acc_no4;mean_dot_acc_no5;mean_dot_acc_no05};
        all_arabic_CI = {arabicCI_no0, arabicCI_no1,arabicCI_no2,arabicCI_no3,arabicCI_no4,arabicCI_no5,arabicCI_no05};
        all_dot_CI = {dotCI_no0, dotCI_no1,dotCI_no2,dotCI_no3,dotCI_no4,dotCI_no5,dotCI_no05};
        ci_colours = {[1, 0, 0],[1, 165/255, 0],[50/255, 205/255, 50/255],[0, 1, 1],[0, 0, 1],[1,0,1],[0,0,0]};		

        figure;
        subplot(1,2,1)  
        for num = 1:length(all_arabic)
            all_arabic_acc = all_arabic{num};
            mean_arabic_diag = all_arabic_acc';
            
            arabic_CIs = all_arabic_CI{num};

            upperCI = mean_arabic_diag+arabic_CIs;
            lowerCI = mean_arabic_diag-arabic_CIs; 
            x = [arabic_time(1:5:length(arabic_time)), fliplr(arabic_time(1:5:length(arabic_time)))];
            inBetween = [upperCI(1:5:length(arabic_time)), fliplr(lowerCI(1:5:length(arabic_time)))];
            fill(x, inBetween,'b', 'FaceColor',ci_colours{num},'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');

                  hold on;
            
            plot(arabic_time(1:5:length(arabic_time)),mean_arabic_diag(1:5:length(arabic_time)),'Color', ci_colours{num}, 'LineWidth', 1);
            xlim([arabic_time(1) arabic_time(end)]);
            ylim([0.15 0.3])
            title('Train on Numerals');
            

            xlabel('Time (s)')
            ylabel('Accuracy')

            hold on
            
        end        
        yline(1/5,'--');
        yline(1/4,'--')

        subplot(1,2,2)  
        for num = 1:length(all_dots)
            all_dot_acc = all_dots{num};
            mean_dot_diag = all_dot_acc';
            
            dot_CIs = all_dot_CI{num};

            upperCI = mean_dot_diag+dot_CIs;
            lowerCI = mean_dot_diag-dot_CIs; 
            x = [dot_time(1:5:length(dot_time)), fliplr(dot_time(1:5:length(dot_time)))];
            inBetween = [upperCI(1:5:length(dot_time)), fliplr(lowerCI(1:5:length(dot_time)))];
            fill(x, inBetween,'b', 'FaceColor',ci_colours{num},'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');

                  hold on;
            
            plot(dot_time(1:5:length(dot_time)),mean_dot_diag(1:5:length(dot_time)),'Color', ci_colours{num}, 'LineWidth', 1);
            xlim([dot_time(1) dot_time(end)]);
            ylim([0.15 0.3])
            title('Train on Dots');
            

            xlabel('Time (s)')
            ylabel('Accuracy')

            hold on
        end
        yline(1/5,'--');
        yline(1/4,'--')
        legend('','No Zero','','No One','','No Two','','No Three','','No Four','','No Five','','No Zero or Five');

    end
end