function plot_multiclass_temp_det(cfg0, subjects)
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
            house_acc = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_house_acc.mat'));
            face_acc = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_face_acc.mat'));
            %Confusion Matrices
            house_conf_tmp = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_house_confusion.mat'));
            face_conf_tmp = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_face_confusion.mat'));
        elseif strcmp(cfg0.decoding_type,'within')
            %Accuracy
            house_acc = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_house_acc.mat'));
            face_acc = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_face_acc.mat'));   
            %Confusion Matrix
            house_conf_tmp = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_house_confusion.mat'));
            face_conf_tmp = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_face_confusion.mat'));
        else
            warning('Decoding Type Not Recognised');
        end
        
        %Group Accuracies
        house_acc = struct2cell(house_acc); house_acc = house_acc{1};
        face_acc = struct2cell(face_acc); face_acc = face_acc{1};

        all_house_acc(subj,:,:) = house_acc;
        all_face_acc(subj,:,:) = face_acc;
        
        clear house_acc face_acc

        %Group Confusion Matrices
        house_conf_tmp = struct2cell(house_conf_tmp); house_conf_tmp = house_conf_tmp{1};
        face_conf_tmp = struct2cell(face_conf_tmp); face_conf_tmp = face_conf_tmp{1};

        %Only interested in confusion matrix of diagonal decoding
        %So we extract diagonal from the temporal generalisation matrix
        for trnT = 1:size(house_conf_tmp,1)
            house_conf(trnT,:,:) = squeeze(house_conf_tmp(trnT,:,:,trnT));
        end
        for trnT = 1:size(face_conf_tmp,1)
            face_conf(trnT,:,:) = squeeze(face_conf_tmp(trnT,:,:,trnT));
        end

        all_house_conf(subj,:,:,:) = house_conf;
        all_face_conf(subj,:,:,:) = face_conf;

        clear house_conf face_conf house_conf_tmp face_conf_tmp
    end
    
    %% Compute Average Accuracies
    mean_house_acc = squeeze(mean(all_house_acc,1));
    mean_face_acc = squeeze(mean(all_face_acc,1));

    %% Compute Average Confusion Matrices
    mean_house_conf = squeeze(mean(all_house_conf,1));
    mean_face_conf = squeeze(mean(all_face_conf,1));

    %% Plot Temporal Generalisation Matrices
    if strcmp(cfg0.decoding_type,'cross')
        titles = {'Train on house, Test on face', 'Train on face, Test on house','Train on house: Diagonal','Train on face: Diagonal'};
    else
        titles = {'house Decoding', 'face Decoding','house Decoding: Diagonal','face Decoding: Diagonal'};
    end
    confusion_titles = {'Abs-High','Abs-Low','Pres-Low','Pres-High','Abs-High','Abs-Low','Pres-Low','Pres-High',};

    %Train on houseber, Test on Decoding
    figure('units','normalized','outerposition',[0 0 1 1])
    subplot(3,8,[1.5,3.5]);
    imagesc(time,time,mean_house_acc); axis xy; %colorbar
    xlabel('Train Time (s)'); ylabel('Test Time (s)');
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    caxis(cfg0.clim)
    colormap('jet')
    title(titles{1});
    
    %Train on Decoding, Test on houseber
    subplot(3,8,[5.5,7.925]);
    imagesc(time,time,mean_face_acc); axis xy; colorbar
    xlabel('Train Time (s)'); 
    hold on; plot([0 0],ylim,'r'); hold on; plot(xlim,[0 0],'r');
    hold on; plot([1 1],ylim,'k'); hold on; plot(ylim,[1 1],'k')
    caxis(cfg0.clim)
    colormap('jet')
    title(titles{2});
   
    %% Extract Diagonal Decoding
    %Train on housebers
    all_house_diags = zeros(2,length(time));
    for i = 1:size(all_house_acc,1)
        all_house_diags(i,:) = diag(squeeze(all_house_acc(i,:,:)));
    end

    mean_house_diag = diag(mean_house_acc)';
    house_CIs = CalcCI95(all_house_diags);

    subplot(3,8,[9,12])      
    upperCI = mean_house_diag+house_CIs;
    lowerCI = mean_house_diag-house_CIs; 
    x = [time, fliplr(time)];
    inBetween = [upperCI, fliplr(lowerCI)];
    fill(x, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time,mean_house_diag,'Color', '#0621A6', 'LineWidth', 1);
    yline(0.25,'black--');
    xlim([time(1) time(end)]);
    ylim(cfg0.ylim)
    title(titles{3});
    xline(time(end));
    xlabel('Time (s)')
    ylabel('Accuracy')
    
    %Train on faceection
    all_face_diags = zeros(2,length(time));
    for i = 1:size(all_face_acc,1)
        all_face_diags(i,:) = diag(squeeze(all_face_acc(i,:,:)));
    end
    mean_face_diag = diag(mean_face_acc)';
    face_CIs = CalcCI95(all_face_diags);

    subplot(3,8,[13,16])      
    upperCI = mean_face_diag+face_CIs;
    lowerCI =mean_face_diag-face_CIs; 
    x = [time, fliplr(time)];
    inBetween = [upperCI, fliplr(lowerCI)];
    fill(x, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    hold on;
    plot(time,mean_face_diag,'Color', '#0621A6', 'LineWidth', 1);
    yline(0.25,'black--');
    title(titles{4});
    xlim([time(1) time(end)]);
    ylim(cfg0.ylim)
    xline(time(end));
    xlabel('Time (s)')

    %% Plot Confusion Matrices
    if strcmp(cfg0.decoding_type,'cross')
        confusion_titles = {'Abs-High','Abs-Low','Pres-Low','Pres-High','Abs-High','Abs-Low','Pres-Low','Pres-High'};
    else
        confusion_titles = {'Abs-High','Abs-Low','Pres-Low','Pres-High','Abs-High','Abs-Low','Pres-Low','Pres-High'};
    end
    leg = {{'Abs-High','Abs-Low','Pres-Low','Pres-High'},{'Abs-High','Abs-Low','Pres-Low','Pres-High'}};

    %Train on houseber
    house_CIs = CalcCI95(all_house_conf);
    
    t = time(1:10:length(time));
    for true_class = 1:size(mean_house_conf,2)

        %Each loop will be a new plot
        %choose every 10th element for smoothing
        zero = mean_house_conf(1:10:length(time),true_class,1);
        one = mean_house_conf(1:10:length(time),true_class,2);
        two = mean_house_conf(1:10:length(time),true_class,3);
        three = mean_house_conf(1:10:length(time),true_class,4);
        conditions = {zero; one;two; three};

        %f = figure;
        %f.Position = [200 300 250 350];
        subplot(3,8,16+true_class)
        %f.Position = [200 300 250 350];

        curve1 = cell2mat(conditions(true_class))'+house_CIs(1:10:length(time));
        curve2 =cell2mat(conditions(true_class))'-house_CIs(1:10:length(time));
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

    %Train on faceection
    face_CIs = CalcCI95(all_face_conf);

    for true_class = 1:size(mean_face_conf,2)

        %Each loop will be a new plot
        %choose every 10th element for smoothing
        zero = mean_face_conf(1:10:length(time),true_class,1);
        one = mean_face_conf(1:10:length(time),true_class,2);
        two = mean_face_conf(1:10:length(time),true_class,3);
        three = mean_face_conf(1:10:length(time),true_class,4);
        conditions = {zero; one;two; three};

        %f = figure;
        %f.Position = [200 300 250 350];
        f = subplot(3,8,20+true_class);
        %f.Position = [200 300 250 350];
        
        curve1 = cell2mat(conditions(true_class))'+face_CIs(1:10:length(time));
        curve2 =cell2mat(conditions(true_class))'-face_CIs(1:10:length(time));
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

    %% Save
    outputDir = fullfile(cfg0.root,cfg0.output_path,'Group');
    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end
    
    fig = gcf;
    saveas(fig,fullfile(outputDir,[cfg0.figName,'.png']));
    save(fullfile(outputDir,cfg0.accFile),'mean_house_acc','mean_house_diag',"mean_face_acc",'mean_face_diag');

  
end