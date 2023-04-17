function meanNumberConfusion(cfg0,subjects)

    %% Output Directory
    outputDir = fullfile(cfg0.root,cfg0.output_path,'Group');
    if ~exist(outputDir,'dir'); mkdir(outputDir); end

    %% Load Confusion Matrices
    dot_confs = [];
    for subj = 1:length(subjects)
        subject = subjects{subj};

        disp('loading..')
        disp(subject)
        dot_conf = load(fullfile(cfg0.root,'Analysis','MEG','Multiclass_Decoding','TimeAveraged',subject,'number_confusion_dots.mat'));
        dot_conf = dot_conf.conf_dots;  
        dot_confs(subj,:,:) =  dot_conf.conf;

        arabic_conf = load(fullfile(cfg0.root,'Analysis','MEG','Multiclass_Decoding','TimeAveraged',subject,'number_confusion_arabic.mat'));
        arabic_conf = arabic_conf.conf_arabic;  
        arabic_confs(subj,:,:) =  arabic_conf.conf;


    
    end
    
    %% Average Over Subjects
    mean_dot_conf = squeeze(mean(dot_confs,1));
    mean_arab_conf = squeeze(mean(arabic_confs,1));

    %% Plot Confusion Matrix
    figure;
    subplot(2,2,1)
    imagesc(mean_dot_conf)
    colormap(jet(512))
    xtick = [0,1,2,3,4,5];
    ytick = [0,1,2,3,4,5];
    set(gca, 'XTick',xtick+1, 'XTickLabel',xtick,'YTickLabel',ytick)   
    ylabel('True Class')
    xlabel('Predicted Class')
    a = colorbar;
    a.Label.String = 'Proportion Classified';
    text(8,0.05,'DOTS');

    subplot(2,2,3)
    imagesc(mean_arab_conf)
    colormap(jet(512))
    xtick = [0,1,2,3,4,5];
    ytick = [0,1,2,3,4,5];
    set(gca, 'XTick',xtick+1, 'XTickLabel',xtick,'YTickLabel',ytick)   
    ylabel('True Class')
    xlabel('Predicted Class')
    a = colorbar;
    a.Label.String = 'Proportion Classified';
        text(8,0.05,'NUMERALS');

    %% Create MEG Tuning Curves
    zero = mean_dot_conf(:,1);
    one = mean_dot_conf(:,2);
    two = mean_dot_conf(:,3);
    three = mean_dot_conf(:,4);
    four = mean_dot_conf(:,5);
    five = mean_dot_conf(:,6);

    curves = {zero one two three four five};
    
    %plot
    subplot(2,2,2)
    x = [0 1 2 3 4 5];
 
    colors = {'red','#FFA500','#32CD32','cyan','magenta','green'};
    for cl = 1:length(curves)
        curve = curves{cl};
        plot(x,curve,'Color',colors{cl},'LineWidth' , 2)
        xticks([0 1 2 3 4 5]);
        ylabel('Prop. Predicted')
        xlabel('True Number')
        
        hold on
    end
    legend({'Zero' 'One' 'Two' 'Three' 'Four' 'Five'}); %true classes
   
    %% Create MEG Tuning Curves
    zero = mean_arab_conf(:,1);
    one = mean_arab_conf(:,2);
    two = mean_arab_conf(:,3);
    three = mean_arab_conf(:,4);
    four = mean_arab_conf(:,5);
    five = mean_arab_conf(:,6);

    curves = {zero one two three four five};
    
    %plot
    subplot(2,2,4)
    x = [0 1 2 3 4 5];
 
    colors = {'red','#FFA500','#32CD32','cyan','magenta','green'};
    for cl = 1:length(curves)
        curve = curves{cl};
        plot(x,curve,'Color',colors{cl},'LineWidth' , 2)
        xticks([0 1 2 3 4 5]);
        ylabel('Prop. Predicted')
        xlabel('True Number')
        
        hold on
    end
    legend({'Zero' 'One' 'Two' 'Three' 'Four' 'Five'}); %true classes
   

    %% Save
    saveas(gcf,fullfile(outputDir,'numerical_confusion.png'))


end