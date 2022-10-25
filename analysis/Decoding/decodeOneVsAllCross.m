function [peak_samples,peak_times] =  decodeOneVsAllCross(cfg0,subjects)

for subj = 1:length(subjects)
    subject = subjects{subj};
    
    
    %% Load MEG data
    disp('loading..')
    disp(subject)
    det_data = load(fullfile(cfg0.root,'CleanData',subject,'det_data.mat'));
    det_data = det_data.det_data;  
    num_data = load(fullfile(cfg0.root,'CleanData',subject,'num_data.mat'));
    num_data = num_data.num_data;  
    time = num_data.time{1};
    disp('loaded data')
    
    %% Organise Detection Data
    % Only keep trials with detection and confidence responses
    cfgS = [];
    cfgS.trials =~(det_data.no_det_resp);
    det_data = ft_selectdata(cfgS,det_data);
    
    %% Store class labels
    det_labels = det_data.det_labels;
    num_labels = num_data.num_labels;
    
    %% Get Trial x Channels x Time Matrix For Each Task
    cfgS = [];
    cfgS.keeptrials = true;
    cfgS.channel=cfg0.channel;
    det_data = ft_timelockanalysis(cfgS,det_data);
    
    cfgS = [];
    cfgS.keeptrials = true;
    cfgS.channel=cfg0.channel;
    num_data = ft_timelockanalysis(cfgS,num_data);
    
    %% Smooth Data
    smoothed_det_data = zeros(size(det_data.trial));
    for trial = 1:size(det_data.trial,1)
        smoothed_det_data(trial,:,:) = ft_preproc_smooth(squeeze(det_data.trial(trial,:,:)),cfg0.nMeanS);
    end
    smoothed_num_data = zeros(size(num_data.trial));
    for trial = 1:size(num_data.trial,1)
        smoothed_num_data(trial,:,:) = ft_preproc_smooth(squeeze(num_data.trial(trial,:,:)),cfg0.nMeanS);
    end
    
    %% Binary One Vs. All Decoding Within Domain  
    datasets = {smoothed_num_data, smoothed_det_data};
    names = {'Number','Detection'};
    data_labels = {num_labels,det_labels};
    task_accs = {};
    for dataset = 1:length(datasets)
        sprintf('Decoding %s dataset', names{dataset});

        ds = datasets{dataset};
        lbls = data_labels{dataset};
        
        cfgS = [];
        cfgS.classifier = 'logreg';
        cfgS.metric = 'acc';
        cfgS.preprocess ={'undersample_multibin','zscore'};
        cfgS.repeat = 1;
        cfgS.labels = lbls;
        cfgS.reg = 'l2';
        cfgS.lambda = 0.01;
        accs = one_v_all(cfgS,ds,lbls);
        
        %Calculate mean accuracy over four classifiers
        mean_acc = mean(accs,2);   
        subj_accs(subj,:) = mean_acc;
        
        %Save accuracy averaged over four classifiers for each subject
        outputDir = fullfile(cfg0.root,cfg0.output_path,subject,names{dataset});
        if ~exist(outputDir,'dir'); mkdir(outputDir); end 
        save(fullfile(outputDir,'mean_acc.mat'),'mean_acc');

        task_accs{dataset} = subj_accs;
    end
    
end
clear accs mean_acc accuracy num_data det_data

%% Extract Peak Decoding Time Point
peak_samples = {};
peak_times = {};
for task = 1:size(task_accs,2)
    subj_accs = task_accs{task};
    cfgP = {};
    cfgP.time = time;
    cfgP.name = names{task};
    cfgP.plot = cfg0.plot;
    [peak_samples{task},peak_times{task}] = get_peak_time(cfgP,subj_accs);
end
drawnow;

%% Train Decoders on All Trials At Peak Time Point
task_group_dvals = {};
task_group_CIs = {};
for task = 1:size(data_labels,2)
    
    cfgT = cfg0;
    cfgT.taskIdx = task;
    cfgT.peak_sample = peak_samples{task};
    cfgT.name = names{task};
    [subj_dvals,subj_probs] = cross_one_v_all(cfgT,subjects);
    
    %% Group Level Distance Vals (Standardised Within Subjects)
    %Average over subjects
    group_dvals = {};
    group_CIs = {};
    for decoder = 1:size(subj_dvals,2)
        %Get Training Decoder
        dvals = cat(1,subj_dvals{:,decoder});

        %Average dvals on test classes across subjects
        dvals_test_c1 = cat(1,dvals{:,1});
        group_dvals{decoder,1}  = mean(dvals_test_c1,1);
        group_CIs{decoder,1} = CalcCI95(dvals_test_c1);
        dvals_test_c2 = cat(1,dvals{:,2});
        group_dvals{decoder,2}  = mean(dvals_test_c2,1);
        group_CIs{decoder,2} = CalcCI95(dvals_test_c2);
        dvals_test_c3 = cat(1,dvals{:,3});
        group_dvals{decoder,3}  = mean(dvals_test_c3,1);
        group_CIs{decoder,3} = CalcCI95(dvals_test_c3);
        dvals_test_c4 = cat(1,dvals{:,4});
        group_dvals{decoder,4}  = mean(dvals_test_c4,1);
        group_CIs{decoder,4} = CalcCI95(dvals_test_c4);

    
        %group_dvals is a [decoder x test class] cell array. Each cell is an 
        % array of group level distance values. Probably need to standardise the before this step.
        
        %Do the same for probabilitie
        probs = cat(1,subj_probs{:,decoder});

        probs_test_c1 = cat(1,probs{:,1});
        group_probs{decoder,1}  = mean(probs_test_c1,1);
        group_probCIs{decoder,1} = CalcCI95(probs_test_c1);
        probs_test_c2 = cat(1,probs{:,2});
        group_probs{decoder,2}  = mean(probs_test_c2,1);
        group_probCIs{decoder,2} = CalcCI95(probs_test_c2);
        probs_test_c3 = cat(1,probs{:,3});
        group_probs{decoder,3}  = mean(probs_test_c3,1);
        group_probCIs{decoder,3} = CalcCI95(probs_test_c3);
        probs_test_c4 = cat(1,probs{:,4});
        group_probs{decoder,4}  = mean(probs_test_c4,1);
        group_probCIs{decoder,4} = CalcCI95(probs_test_c4);
    
    end
    task_group_dvals{task} = group_dvals;
    task_group_CIs{task} = group_CIs;
    task_group_probs{task} = group_probs;
    task_group_probCIs{task} = group_probCIs;
    %Save
    grpOutputDir = fullfile(cfg0.root,cfg0.output_path,'Group',names{task});
    if ~exist(grpOutputDir,'dir'); mkdir(grpOutputDir); end 
    save(fullfile(grpOutputDir,'d_vals'),'group_dvals')
end

%% Plot
if cfg0.plot
    
    colours = {[0, 0.4470, 0.7410, 0.6],[0.8500, 0.3250, 0.0980, 0.6],[0.9290, 0.6940, 0.1250,0.6],[0.4940, 0.1840, 0.5560,0.6]};		
    ci_colours = {[0, 0.4470, 0.7410],[0.8500, 0.3250, 0.0980],[0.9290, 0.6940, 0.1250],[0.4940, 0.1840, 0.5560]};		 
    
    %% Probability Plots
    figure('units','normalized','outerposition',[0 0 1 1]);
    class_names = {'Zero','One','Two','Three'};
    group_probs = task_group_probs{1};
    group_probCIs = task_group_probCIs{1};
    for clf = 1:size(group_probs,1)
        subplot(2,4,clf)
        fprintf('Using Decoder %d of %d \n',clf,size(group_probs,2))
        for test_class = 1:size(group_probs,2)
            ax = plot(time,group_probs{clf,test_class},'Color',cell2mat(colours(test_class)),'LineWidth',1);
            hold on;
            xlabel('Time (Seconds)')
            title([class_names{clf},' ','Decoder'])
            xlim([time(1) time(end)])

            upperCI = group_probs{clf,test_class}+group_probCIs{clf,test_class};
            lowerCI =  group_probs{clf,test_class}-group_probCIs{clf,test_class};
            x = [time, fliplr(time)];
            inBetween = [upperCI, fliplr(lowerCI)];
            fill(x, inBetween,'b', 'FaceColor',cell2mat(ci_colours(test_class)),'FaceAlpha','0.1','EdgeAlpha','0.2','EdgeColor','none');
            hold on;
            xline(peak_times{1},'--r')

        end
        
        if clf == 1
            legend('Abs-High','','','Abs-Low','','','Pres-Low','','','Pres-High','Location','best')
            ylabel('Probability')
        end
        hold off;

    
    
    end

    %Detection
    class_names = {'Abs-High','Abs-Low','Pres-Low','Pres-High'};
    group_probs = task_group_probs{2};
    group_probCIs = task_group_probCIs{2};
    for clf = 1:size(group_probs,1)
        subplot(2,4,clf+4)
        fprintf('Using Decoder %d of %d \n',clf,size(group_probs,2))
        for test_class = 1:size(group_probs,2)
            ax = plot(time,group_probs{clf,test_class},'Color',cell2mat(colours(test_class)),'LineWidth',1);
            hold on;
            xlabel('Time (Seconds)')
            title([class_names{clf},' ','Decoder'])
            xlim([time(1) time(end)])
            
            upperCI = group_probs{clf,test_class}+group_probCIs{clf,test_class};
            lowerCI =  group_probs{clf,test_class}-group_probCIs{clf,test_class};
            x = [time, fliplr(time)];
            inBetween = [upperCI, fliplr(lowerCI)];
            fill(x, inBetween,'b', 'FaceColor',cell2mat(ci_colours(test_class)),'FaceAlpha','0.1','EdgeAlpha','0.2','EdgeColor','none');
            hold on;           
            xline(peak_times{2},'--r')

        end

        if clf == 1
            legend('Zero','','','One','','','Two','','','Three','Location','best')
            ylabel('Probability')
        end
        hold off;
    
    end
    figOutputDir = fullfile(cfg0.root,cfg0.output_path,'Group');
    if ~exist(figOutputDir,'dir'); mkdir(figOutputDir); end 
    fig = gcf;
    saveas(fig,fullfile(figOutputDir,[cfg0.figName,'.png']));

end


end
