function onesample_corrected(cfg,subjects)
% Run a one-sample test on accuracy scores while correcting
% the temporal generlisation matrices for multiple comparisons.
% Plots the matrix and diagonal with significant clusters outlined.

outputDir = fullfile(cfg.root,cfg.output_path,'Group','Stats');
if ~exist(outputDir,'dir')
    mkdir(outputDir)
end
    
time = load('time_axis.mat');
time = time.t;

num_acc = zeros(length(subjects),length(time),length(time));
det_acc=zeros(length(subjects),length(time),length(time));

%% Load Accuracy Matrices
for subj =1:length(subjects)

   subject = subjects{subj};
   disp(subject)
   
       
   num_acc = load(fullfile(cfg.root,cfg.output_path,subject,cfg.resultsFile{1}));
   num_acc = struct2cell(num_acc); num_acc = num_acc{1};
    
   det_acc = load(fullfile(cfg.root,cfg.output_path,subject,cfg.resultsFile{2}));
   det_acc = struct2cell(det_acc); det_acc = det_acc{1};
    
   all_num_acc(subj,:,:) = num_acc;
   all_det_acc(subj,:,:) = det_acc;
   
end

%% Run Correction Procedure
cfgS = [];cfgS.paired = false;cfgS.tail= 'one'; cfgS.indiv_pval = 0.05; cfgS.cluster_pval = 0.05;

fprintf('Correcting Data with %d subjects with %d train and %d test time-points each \n',size(all_num_acc,1),size(all_num_acc,3),size(all_num_acc,2));
pVals_onesamp_num = cluster_based_permutationND(all_num_acc,0.25,cfgS);
save(fullfile(outputDir,'pVals_train_num.mat'),'pVals_onesamp_num')

fprintf('Correcting Data with %d subjects with %d train and %d test time-points each \n',size(all_det_acc,1),size(all_det_acc,3),size(all_det_acc,2));
pVals_onesamp_det = cluster_based_permutationND(all_det_acc,0.25,cfgS);
save(fullfile(outputDir,'pVals_train_det.mat'),'pVals_onesamp_det')

