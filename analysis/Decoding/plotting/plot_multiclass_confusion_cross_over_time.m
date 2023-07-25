function plot_multiclass_confusion_cross_over_time(cfg0, subjects)
% Plot confusion matrix averaged over time, with timepoints defined by user (time points of significant cross-decoding)
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

    %% Average Over Time
    beg_sample = find(arabic_time==0.1);
    end_sample = find(arabic_time == 0.16);

    mean_arabic_conf = squeeze(mean(mean_arabic_conf(beg_sample:end_sample,:,:),1));
    mean_dot_conf = squeeze(mean(mean_dot_conf(beg_sample:end_sample,:,:),1));

    %% Plot Confusion Matrix
    figure;
    subplot(1,2,1)
    imagesc(mean_arabic_conf)
    colormap(jet(512))
    xtick = [0,1,2,3,4,5];
    ytick = [0,1,2,3,4,5];
    set(gca, 'XTick',xtick+1, 'XTickLabel',xtick,'YTickLabel',ytick)   
    ylabel('True Class (Dots)')
    xlabel('Predicted Class')
    a = colorbar;
    a.Label.String = 'Proportion Classified';
    title('Train on Arabic')

    subplot(1,2,2)
     imagesc(mean_dot_conf)
    colormap(jet(512))
    xtick = [0,1,2,3,4,5];
    ytick = [0,1,2,3,4,5];
    set(gca, 'XTick',xtick+1, 'XTickLabel',xtick,'YTickLabel',ytick)   
    ylabel('True Class (Arabic)')
    xlabel('Predicted Class')
    a = colorbar;
    a.Label.String = 'Proportion Classified';
        title('Train on Dots');

  
end