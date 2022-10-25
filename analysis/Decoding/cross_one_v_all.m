function [subj_dvals,subj_probs] = cross_one_v_all(cfg0,subjects)
    %Trains decoder on one time point and tests it on all time points
    %in the other domain.

    subj_dvals = {};
    for subj = 1:length(subjects)
        subject = subjects{subj};
         
        %% Load MEG data
        disp('loading..')
        disp(subject)
        det_data = load(fullfile(cfg0.root,'CleanData',subject,'det_data.mat'));
        det_data = det_data.det_data;  
        num_data = load(fullfile(cfg0.root,'CleanData',subject,'num_data.mat'));
        num_data = num_data.num_data;  
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

        datasets = {zscore(smoothed_num_data),zscore(smoothed_det_data)};
        data_labels = {num_labels,det_labels};

        %% Train Decoders on Peak Sample
        best_decoders ={};
        classes = unique(data_labels{cfg0.taskIdx});
        
        for class = 1:length(classes)
            %Train binary one vs. all on all trials (i.e. no CV)
            labels = data_labels{cfg0.taskIdx}==class;
            cfgS.cv = 'none';
            cfgS.repeat = 1;
            cfgS.preprocess = {'undersample'};
            cfgS.classifier = 'logreg';
            cfgS.output_type = 'dval';
            cfgS.reg = 'l2';
            cfgS.lambda = 0.01;
            d = datasets{cfg0.taskIdx};
            [~,~,~,clf] = mv_classify_BOB(cfgS,d(:,:,cfg0.peak_sample),labels);
            best_decoders{class} = clf;
        end
        
        
        %% Test Best Decoders on New Domain
        for clf = 1:length(best_decoders)
            decoder = best_decoders{clf};
            test_dvals ={};
            test_probs = {};
            for test_class = 1:length(classes)
                %Select only 1 test class at a time
                if cfg0.taskIdx == 1
                    d = datasets{2};
                    labels = data_labels{2} == test_class;
                elseif cfg0.taskIdx == 2
                    d = datasets{1};
                    labels = data_labels{1} == test_class;
                end
                %d = datasets{cfg0.taskIdx};
                %labels = data_labels{cfg0.taskIdx} == test_class;
                data = d(labels,:,:); 
                dvals_x_time = [];
                for t = 1:size(data,3)
                    [~,dvals] = test_logreg(decoder,data(:,:,t));
                    av_dval = mean(dvals,1); %average classifier evidence of all trials
                    dvals_x_time(:,t)= av_dval;                
                end
                test_dvals{test_class} = dvals_x_time;
                test_probs{test_class} = 0.5 + 0.5 * tanh(0.5 * test_dvals{test_class});
            end
            %Save all decision values for each classifier and test class for each subject
            outputDir = fullfile(cfg0.root,cfg0.output_path,subject,cfg0.name);
            if ~exist(outputDir,'dir'); mkdir(outputDir); end 
            save(fullfile(outputDir,['test_dval_',num2str(clf),'.mat']),'test_dvals');
            subj_dvals{subj,clf} = test_dvals;
            subj_probs{subj,clf} = test_probs;
        end
    end

end