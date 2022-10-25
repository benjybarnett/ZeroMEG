function [subj_dvals,subj_probs] = within_one_v_all(cfg0,subjects)
    %Trains decoder on one time point and tests it on all time points
    %in the same domain. Uses cross-validation.

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

        datasets = {smoothed_num_data,smoothed_det_data};
        data_labels = {num_labels,det_labels};

        %% Train Decoders on Peak Sample
        best_decoders ={};
        kfold_testidxs = {};
        classes = unique(data_labels{cfg0.taskIdx});
        
        for class = 1:length(classes)
            %Decode binary one vs. all with CV
            labels = data_labels{cfg0.taskIdx};
            
            cfgS.cv = 'leaveout';
            cfgS.output_type = 'dval';
            cfgS.param.prob = 0;
            d = datasets{cfg0.taskIdx};
            cfgS.repeat = 1;
            cfgS.preprocess = {'undersample_multibin','zscore'};
            pparam = {};
            pparam.target_class = class;
            cfgS.preprocess_param = {pparam};
            cfgS.classifier = 'logreg';
            cfgS.hyperparameter.reg = 'l2';
            cfgS.hyperparameter.lambda = 0.01;
            [~,~,~,clfs,test_idxs] = mv_classify_BOB(cfgS,d(:,:,cfg0.peak_sample),labels);            
            best_decoders{class} = clfs;
            kfold_testidxs{class} = test_idxs;%use this to test on unseen classes in testing phase
            %best_decoders is a [1xclasses] cell array, with each cell
            %having the N leave-one-out-fold classifiers

        end
        
        
        %% Test Best Decoders on Same Domain with CV
        
        test_dvals = cell(length(best_decoders),length(classes));
        for clf = 1:length(best_decoders)
            disp(clf)
            decoder = best_decoders{clf};
            testidxs = kfold_testidxs{clf};
            d = datasets{cfg0.taskIdx};
            for test_class = 1:length(classes)  
                kfold_dvals = [];
                for kfold = 1:length(decoder)
                    kfold_decoder = decoder{kfold};
                    kfold_testidx = testidxs{kfold};
                    %Select only 1 test class at a time   
                    labels = data_labels{cfg0.taskIdx} == test_class;
                    if labels(kfold_testidx) %if test sample is in test class of interest
                        data = d(kfold_testidx,:,:); 

                        zdata = d(~kfold_testidx,:,:); %get training data for use in zscoring 
                        zmean = mean(zdata, 1);
                        zsd = std(zdata, [], 1);
                    else 
                        continue;
                    end
                    dvals_x_time = [];
                    for t = 1:size(data,3)
                        test_data = data(:,:,t);

                        test_data = test_data - zmean(:,:,t);
                        test_data = test_data ./ zsd(:,:,t);
                        [~,dvals] = test_logreg(kfold_decoder,test_data);

                        dvals_x_time(:,t)= dvals; 
                    end
                   
                    kfold_dvals(kfold,:)= dvals_x_time;
                end
                test_dvals{clf,test_class} = mean(kfold_dvals,1,'omitnan');
                test_probs{clf,test_class} = 0.5 + 0.5 * tanh(0.5 * test_dvals{clf,test_class});
            end

            %Save all decision values for each classifier and test class for each subject
            outputDir = fullfile(cfg0.root,cfg0.output_path,subject,cfg0.name);
            if ~exist(outputDir,'dir'); mkdir(outputDir); end 
            save(fullfile(outputDir,['test_dval_',num2str(clf),'.mat']),'test_dvals');
            subj_dvals{subj} = test_dvals;
            subj_probs{subj} = test_probs;
            
        end
        
    end

end