%% Multidimensional Scaling
close all
root = 'D:\bbarnett\Documents\Zero\data';
start_time =xx;
end_time =xx;

for subj = 1:length(subjects)
    %% Load Data
    disp('loading..')
    subject = subjects{subj};
    disp(subject)
    dot_data = load(fullfile(root,'CleanData',subject,'dot_trials.mat'));
    dot_data = dot_data.dot_trials;
    dot_time = dot_data.time{1};
    disp('loaded data')

    

    %% Select Sample Dot Stims
    cfgS = [];
    cfgS.trials = dot_data.trialinfo(:,4) == 1;
    dot_data = ft_selectdata(cfgS,dot_data);

    %% Remove No Resp Trials
    cfgS = [];
    cfgS.trials = dot_data.trialinfo(:,8) ~= 0;
    dot_data = ft_selectdata(cfgS,dot_data);
    

    %% Create Design Matrix of Dummy Coded Predictors
    % Dots
    trial_info = dot_data.trialinfo;
    dots_des_mat = zeros(length(trial_info),6);

    % Get Indexes of Different Classes of Interest
    labels = dot_data.trialinfo(:,5);
    zero_idx = labels == 0;
    one_idx = labels == 1;
    two_idx = labels == 2;
    three_idx = labels == 3;
    four_idx = labels == 4;
    five_idx = labels == 5;

    % Fill Design Matrix
    dots_des_mat(zero_idx,1)                 = 1;
    dots_des_mat(one_idx,2)                  = 1;
    dots_des_mat(two_idx,3)                  = 1;
    dots_des_mat(three_idx,4)                = 1;
    dots_des_mat(four_idx,5)                 = 1;
    dots_des_mat(five_idx,6)                 = 1;

    %% Get Trial x Channels x Time matrix
    cfgT = [];
    cfgT.keeptrials = 'yes';
    cfgT.channel = 'MEG';
    tl_data_dot = ft_timelockanalysis(cfgT, dot_data);

    %Produces a [Classes x Channels x Time] Matrix of Betas
    cfg = [];
    cfg.confound = dots_des_mat;
    cfg.normalize = 'no';
    cfg.output = 'beta';
    betas = ft_regressconfound(cfg,tl_data_dot);
    betas = betas.beta;

    %% Create Neural RDM for Each Time Point
    nRDMs = {};
    for time = 1:size(betas,3)
        corrs = pdist(betas(:,:,time),'euclidean');
        rdm = squareform(corrs);
        nRDMs(time) = {rdm};
    end

    %Smooth neural RDMs
    nRDMs = cell2mat(permute(nRDMs,[1,3,2])); %change to [Classes x Classes x Time] matrix
    smoothnRDMs =zeros(size(nRDMs));
    window_sz = 60/4; %(window in ms/downsampling rate)
    smooth_filter = unifpdf(1:window_sz,1,window_sz);
    for i = 1:size(nRDMs,1)
        for j = 1:size(nRDMs,2)
            smoothnRDMs(i,j,:) = conv(squeeze(nRDMs(i,j,:)),smooth_filter,'same');
        end
    end
    subjRDMs(subj,:,:,:) = smoothnRDMs;

end


starttime = find(dot_time == start_time); endtime = find(dot_time == end_time);
meanRDM = squeeze(mean(mean(subjRDMs(:,:,:,starttime:endtime),4),1));

figD = figure; hold on;
[mds e] = cmdscale(meanRDM);

%hP(2) = plot(mds(7:12,1),mds(7:12,2),'o-','Color',colz(2,:),'MarkerFaceColor',colz(2,:),'LineWidth',lnwid,'MarkerSize',20);
%text(mds(7:12,1),mds(7:12,2),num2str([1:params.nstim]'),'Color','w','FontSize',16,'FontWeight','normal','HorizontalAlignment','center');
hP(1) = plot(mds(1:6,1),mds(1:6,2),'o-','Color',dot_colour,'MarkerFaceColor',dot_colour,'LineWidth',2,'MarkerSize',20);
text(mds(1:6,1),mds(1:6,2),num2str([0:5]'),'Color','w','FontSize',16,'FontWeight','normal','HorizontalAlignment','center');
