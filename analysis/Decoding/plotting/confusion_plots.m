function confusion_plots(cfg,subjects)


    dir = fullfile(cfg.root,'Analysis','MEG',cfg.task,'NumConfusion');
    load('time_axis.mat')

    
    confusion = zeros(length(subjects),361,4,4);

    for subj =1:length(subjects)
        subject = subjects{subj};
        disp(subject)

        load(fullfile(dir,subject,cfg.conf_file));
        confusion(subj,:,:,:) =conf;
    end
   

    
    
    %confidence intervals
    std_dev = std(confusion,1);
   

    CIs = [];
    for i =1:size(confusion,2)
        sd = std_dev(i);
        n = size(confusion,1);
        CIs(i) = 1.96*(sd/sqrt(n));
    end
    
    %average confusion matrices 
    conf_grp = squeeze(mean(confusion,1));
    
    %the confusion matrices above are dim [361 x 4 x 4]
    %they have a 4 x 4 confusion matrix for every time point
    %each row is the true label and each column corresponds to the label
    %predicted by the classifier. The (i,j)-th element of the matrix
    %specifies how often class i has been classified as class j. The
    %Diagonal contains correctly classified cases.
    
    %per decoder, we want four plots, one for each number. In each of
    %those plots, there will be four lines plotting the proportion of
    %trials classified as each number (i.e. one line for correct
    %classifications and three for incorrect)
    
    time = t(1:10:361);
    titles = {'Zero','One','Two','Three'};
    for true_class = 1:size(conf_grp,2)
       
        
        
        %each loop will be a new plot
        %choose evry 10th element for smoothing
        zero = conf_grp(1:10:361,true_class,1);
        one = conf_grp(1:10:361,true_class,2);
        two = conf_grp(1:10:361,true_class,3);
        three = conf_grp(1:10:361,true_class,4);
        conditions = {zero; one;two; three};

        f = figure;
        f.Position = [200 300 250 350];
        
        curve1 = cell2mat(conditions(true_class))'+CIs(1:10:361);
        curve2 =cell2mat(conditions(true_class))'-CIs(1:10:361);
        x2 = [time, fliplr(time)];
        inBetween = [curve1, fliplr(curve2)];
        
        ci_colours = {[0, 0.4470, 0.7410],[0.8500, 0.3250, 0.0980],	[0.9290, 0.6940, 0.1250],[0.4940, 0.1840, 0.5560]};		
        f = fill(x2, inBetween,cell2mat(ci_colours(true_class)),'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
        f.Annotation.LegendInformation.IconDisplayStyle = 'off';
        hold on;
        chance = yline(0.25,'--','LineWidth', 1.4,'Color','black');
        chance.Annotation.LegendInformation.IconDisplayStyle = 'off';
        
        plot(time,zero,'Color',cell2mat(ci_colours(1)),'LineWidth',1.2);      
        plot(time,one,'Color',cell2mat(ci_colours(2)),'LineWidth',1.2);    
        plot(time,two,'Color',cell2mat(ci_colours(3)),'LineWidth',1.2); 
        plot(time,three,'Color',cell2mat(ci_colours(4)),'LineWidth',1.2);
      
        xlim([min(time),max(time)])
        ylim([0 0.8])
        
        if true_class == 1
            [pos,hobj,~,~] = legend('Zero', 'One', 'Two', 'Three');
            hl = findobj(hobj,'type','line');
            set(hl,'LineWidth',3);
            ht = findobj(hobj,'type','text');
            set(ht,'FontSize',6);
            set(ht,'FontName','Arial');
            set(pos,'position',[0.705 0.175 0.1 0.1])
        end
       
        xlabel('Time (seconds)','FontName','Arial')
        ylabel('Proportion Classified','FontName','Arial')
        title(titles(true_class),'FontName','Arial')
        mkdir(fullfile(dir,'group',cfg.outputDir))
        %saveas(f,char(fullfile(dir,'group',cfg.outputDir,strcat(titles(true_class),'_diamonds.png'))))
    end

   
    
   
   

end