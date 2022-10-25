function decodeOneVsAllWithin(cfg0,subjects)


%% Extract Peak Decoding Time Point
peak_samples = cfg0.peak_samples;
peak_times = cfg0.peak_times;


%% Train Decoders on All Trials At Peak Time Point
names = {'Number','Detection'};

task_group_dvals = {};
task_group_CIs = {};
for task = 1:size(peak_samples,2)
    
    cfgT = cfg0;
    cfgT.taskIdx = task;
    cfgT.peak_sample = peak_samples{task};
    cfgT.name = names{task};
    [subj_dvals,subj_probs] = within_one_v_all(cfgT,subjects);
    
    %% Standardise and Average Over Folds Within Subjects
    av_zsubj_dvals = subj_dvals;

    %% Group Level Distance Vals 
    %Average over subjects
    group_dvals = {};
    group_CIs = {};
    group_probs = {};
    for decoder = 1:size(av_zsubj_dvals{1},1)
        for test_class = 1:size(av_zsubj_dvals{1},2)
            to_mean = [];
            to_mean_p = [];
            for subject = 1:size(av_zsubj_dvals,2)
                to_mean = [to_mean; av_zsubj_dvals{subject}{decoder,test_class} ];
                to_mean_p = [to_mean_p;subj_probs{subject}{decoder,test_class}];
            end
            group_dvals{decoder, test_class} = mean(to_mean,1,'omitnan');% Get NaN in rare case there were none of a particular test class in a particular fold.
            group_CIs{decoder,test_class} = CalcCI95(to_mean);
            group_probs{decoder,test_class} = mean(to_mean_p,1,'omitnan');
            group_probCIs{decoder,test_class} = CalcCI95(to_mean_p);
        end
    end
    %group_dvals is a [decoder x test class] cell array. Each cell is an 
    % array of group level distance values. 
    
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
    time = load('time_axis.mat');
    time = time.t;
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
            legend('Zero','','','One','','','Two','','','Three','Location','best')
            ylabel('Probability')

        end
        hold off;
        ylim([0.35 0.65])

    
    
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
        ylim([0.35 0.65])

        if clf == 1
            legend('Abs-High','','','Abs-Low','','','Pres-Low','','','Pres-High','Location','best')
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
