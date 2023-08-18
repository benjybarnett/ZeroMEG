%% PCA ANALYSIS 
%Still need to edit paths 
close all;
pc_exp = [];
all_zone = [];
all_ztwo = [];
all_zthree =[];
all_zfour = [];
all_zfive =[];
nComp = 25;
root = 'D:\bbarnett\Documents\Zero\data';
for subj = 1:length(subjects)
    subject = subjects{subj};
    %% Load MEG Number Data
    disp('loading..')
    disp(subject)
    dot_data = load(fullfile(root,'Analysis\MEG\Source\virtualchannels\dots\parietal\',subject,'vChannels.mat'));
    dot_data = dot_data.vChannels;
    dot_time = dot_data.time{1};
    disp('loaded data')

    %% Select Sample Dot Stims
    cfgS = [];
    %cfgS.trials = dot_data.trialinfo(:,5) == 1;
    %dot_data = ft_selectdata(cfgS,dot_data);

    %% Remove No Resp Trials
    cfgS = [];
    %cfgS.trials = dot_data.trialinfo(:,8) ~= 0;
    %dot_data = ft_selectdata(cfgS,dot_data);

    %% PCA
    disp('Doing PCA')
    covar = zeros(numel(dot_data.label));
    for itrial = 1:numel(dot_data.trial)
        currtrial = dot_data.trial{itrial};
        covar = covar + currtrial*currtrial.';
    end
    [~, D] = eig(covar);
    D = sort(diag(D),'descend');
    D = D ./ sum(D);
    Dcum = cumsum(D);
    numcomponent = find(Dcum>.99,1,'first');
    %figure; screeplot(Dcum,'hello')
    %hold on; xline(numcomponent,'r--');

    pc_exp = [pc_exp Dcum(nComp)];
    cfg = [];
    cfg.method = 'pca';
    cfg.demean = 'no';
    cfg.updatesens = 'yes';
    comp = ft_componentanalysis(cfg, dot_data);

    cfg = [];
    cfg.channel = comp.label(1:nComp);
    dot_data = ft_selectdata(cfg,comp);

    %% Average trials per condition
    cfg = [];
    cfg.trials = dot_data.trialinfo(:,1) == 0;
    cfg.keeptrials = 'no';
    dzero = ft_timelockanalysis(cfg,dot_data);
    cfg.trials = dot_data.trialinfo(:,1) == 1;
    done = ft_timelockanalysis(cfg,dot_data);
    cfg.trials = dot_data.trialinfo(:,1) == 2;
    dtwo = ft_timelockanalysis(cfg,dot_data);
    cfg.trials = dot_data.trialinfo(:,1) == 3;
    dthree = ft_timelockanalysis(cfg,dot_data);
    cfg.trials = dot_data.trialinfo(:,1) == 4;
    dfour = ft_timelockanalysis(cfg,dot_data);
    cfg.trials = dot_data.trialinfo(:,1) == 5;
    dfive = ft_timelockanalysis(cfg,dot_data);
    colours = {[1,0,0],[1, 165/255, 0],[50/255, 205/255, 50/255],[0, 1, 1],[0, 0, 1],[1,0,1]};

    figure;
    plot3(dzero.avg(1,:),dzero.avg(2,:),dzero.avg(3,:),'-o','MarkerIndices',61,'Color',colours{1})
    hold on
    plot3(done.avg(1,:),done.avg(2,:),done.avg(3,:),'-o','MarkerIndices',61,'Color',colours{2})
    hold on
    plot3(dtwo.avg(1,:),dtwo.avg(2,:),dtwo.avg(3,:),'-o','MarkerIndices',61,'Color',colours{3})
    hold on
    plot3(dthree.avg(1,:),dthree.avg(2,:),dthree.avg(3,:),'-o','MarkerIndices',61,'Color',colours{4})
    hold on
    plot3(dfour.avg(1,:),dfour.avg(2,:),dfour.avg(3,:),'-o','MarkerIndices',61,'Color',colours{5})
    hold on
    plot3(dfive.avg(1,:),dfive.avg(2,:),dfive.avg(3,:),'-o','MarkerIndices',61,'Color',colours{6})

    xlabel('PC1')
    ylabel('PC2')
    zlabel('PC3')
    grid on
    legend({'Zero','One','Two','Three','Four','Five'});

    zero_one = [];
    zero_two = [];
    zero_three =[];
    zero_four = [];
    zero_five = [];


    for t = 1:length(dzero.avg(1,:))
        zero_one = [zero_one norm(dzero.avg(:,t)'-done.avg(:,t)')];
        zero_two = [zero_two norm(dzero.avg(:,t)'-dtwo.avg(:,t)')];
        zero_three = [zero_three norm(dzero.avg(:,t)'-dthree.avg(:,t)')];
        zero_four = [zero_four norm(dzero.avg(:,t)'-dfour.avg(:,t)')];
        zero_five = [zero_five norm(dzero.avg(:,t)'-dfive.avg(:,t)')];
    end
    all_zone = [all_zone; zero_one];
    all_ztwo = [all_ztwo; zero_two];
    all_zthree =[all_zthree; zero_three];
    all_zfour = [all_zfour; zero_four];
    all_zfive = [all_zfive; zero_five];
    %{
    figure; 
    plot(zero_one,'Color',colours{1});
    hold on
    plot(zero_two,'Color',colours{2});
    plot(zero_three,'Color',colours{3});
    plot(zero_four,'Color',colours{4});
    plot(zero_five,'Color',colours{5});
    legend
    %}


end

mean_zone = mean(all_zone,1);
mean_ztwo = mean(all_ztwo,1);
mean_zthree = mean(all_zthree,1);
mean_zfour = mean(all_zfour,1);
mean_zfive = mean(all_zfive,1);
zone_CI = CalcCI95(all_zone);
ztwo_CI = CalcCI95(all_ztwo);
zthree_CI = CalcCI95(all_zthree);
zfour_CI = CalcCI95(all_zfour);
zfive_CI = CalcCI95(all_zfive);

upperCI_zone = mean_zone+zone_CI;
lowerCI_zone =mean_zone-zone_CI;
x = [dot_time, fliplr(dot_time)];
inBetween_zone = [upperCI_zone, fliplr(lowerCI_zone)];

upperCI_ztwo = mean_ztwo+ztwo_CI;
lowerCI_ztwo =mean_ztwo-ztwo_CI;
inBetween_ztwo = [upperCI_ztwo, fliplr(lowerCI_ztwo)];

upperCI_zthree = mean_zthree+zthree_CI;
lowerCI_zthree =mean_zthree-zthree_CI;
inBetween_zthree = [upperCI_zthree, fliplr(lowerCI_zthree)];

upperCI_zfour = mean_zfour+zfour_CI;
lowerCI_zfour =mean_zfour-zfour_CI;
inBetween_zfour = [upperCI_zfour, fliplr(lowerCI_zfour)];

upperCI_zfive = mean_zfive+zfive_CI;
lowerCI_zfive =mean_zfive-zfive_CI;
inBetween_zfive = [upperCI_zfive, fliplr(lowerCI_zfive)];

figure; plot(dot_time,mean_zone,'Color',[1 0 0],'LineWidth',1.5); hold on;
    fill(x, inBetween_zone,'b', 'FaceColor',[1 0 0],'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');

plot(dot_time,mean_ztwo,'Color',[1 0.25 0],'LineWidth',1.5);
    fill(x, inBetween_ztwo,'b', 'FaceColor',[1 0.25 0],'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');

plot(dot_time,mean_zthree,'Color',[1 0.5 0],'LineWidth',1.5);
    fill(x, inBetween_zthree,'b', 'FaceColor',[1 0.5 0],'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');

plot(dot_time,mean_zfour,'Color',[1 0.75 0],'LineWidth',1.5);
    fill(x, inBetween_zfour,'b', 'FaceColor',[1 0.75 0],'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');

plot(dot_time,mean_zfive,'Color',[1 1 0],'LineWidth',1.5);
    fill(x, inBetween_zfive,'b', 'FaceColor',[1 1 0],'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');

legend('0-1','','0-2','','0-3','','0-4','','0-5');
xlabel('time')
ylabel('Euclidean Distance')
cfgS = [];cfgS.paired = true;cfgS.tail= 'one'; cfgS.indiv_pval = 0.05; cfgS.cluster_pval = 0.05;

pVals = cluster_based_permutationND(all_zone,all_zfive,cfgS);

