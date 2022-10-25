function meanNumberConfusion(cfg0,subjects)

    %% Output Directory
    outputDir = fullfile(cfg0.root,cfg0.output_path,'Group');
    if ~exist(outputDir,'dir'); mkdir(outputDir); end

    %% Load Confusion Matrices
    confs = [];
    for subj = 1:length(subjects)
        subject = subjects{subj};

        disp('loading..')
        disp(subject)
        conf = load(fullfile(cfg0.root,'Analysis','MEG','NumberDecoding',subject,'number_confusion.mat'));
        conf = conf.conf;  
        confs(subj,:,:) =  conf.conf;
    
    end
    
    %% Average Over Subjects
    mean_conf = squeeze(mean(confs,1));

    %% Plot Confusion Matrix
    subplot(1,2,1)
    imagesc(mean_conf)
    colormap(jet(512))
    colorbar;
    
    %% Create MEG Tuning Curves
    zero = mean_conf(1,:);
    one = mean_conf(2,:);
    two = mean_conf(3,:);
    three = mean_conf(4,:);

    curves = {zero one two three};
    
    %plot
    subplot(1,2,2)
    x = [0 1 2 3];
 
    colors = {'red','#FFA500','#32CD32','cyan'};
    for cl = 1:length(curves)
        curve = curves{cl};
        plot(x,curve,'Color',colors{cl},'LineWidth' , 2)
        xticks([0 1 2 3]);
        ylabel('Prop. Predicted as True Number')
        xlabel('Predicted Number')
        
        hold on
    end
    legend({'Zero' 'One' 'Two' 'Three'}); %true classes


    %% Save
    saveas(gcf,fullfile(outputDir,'numerical_confusion.png'))


end