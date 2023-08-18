%% Plot accuracies when removing each numerosity systematically
load('arabic_time.mat')
load('dot_time.mat')

cfg0.outdir = 'Analysis\MEG\Source\Decoding';
for subj =1:length(subjects)
    subject = subjects{subj};
    disp(subject)

    arabic_acc_0 = load(fullfile(cfg0.root,cfg0.outdir,'arabic',cfg0.roi_name,subject,'0.mat'));
    dot_acc_0 = load(fullfile(cfg0.root,cfg0.outdir,'dots',cfg0.roi_name,subject,'0.mat'));
    arabic_acc_1 = load(fullfile(cfg0.root,cfg0.outdir,'arabic',cfg0.roi_name,subject,'1.mat'));
    dot_acc_1 = load(fullfile(cfg0.root,cfg0.outdir,'dots',cfg0.roi_name,subject,'1.mat'));
    arabic_acc_2 = load(fullfile(cfg0.root,cfg0.outdir,'arabic',cfg0.roi_name,subject,'2.mat'));
    dot_acc_2 = load(fullfile(cfg0.root,cfg0.outdir,'dots',cfg0.roi_name,subject,'2.mat'));
    arabic_acc_3 = load(fullfile(cfg0.root,cfg0.outdir,'arabic',cfg0.roi_name,subject,'3.mat'));
    dot_acc_3 = load(fullfile(cfg0.root,cfg0.outdir,'dots',cfg0.roi_name,subject,'3.mat'));
    arabic_acc_4 = load(fullfile(cfg0.root,cfg0.outdir,'arabic',cfg0.roi_name,subject,'4.mat'));
    dot_acc_4 = load(fullfile(cfg0.root,cfg0.outdir,'dots',cfg0.roi_name,subject,'4.mat'));
    arabic_acc_5 = load(fullfile(cfg0.root,cfg0.outdir,'arabic',cfg0.roi_name,subject,'5.mat'));
    dot_acc_5 = load(fullfile(cfg0.root,cfg0.outdir,'dots',cfg0.roi_name,subject,'5.mat'));


    %Group Accuracies
    arabic_acc_0 = struct2cell(arabic_acc_0); arabic_acc_0 = arabic_acc_0{1};
    dot_acc_0 = struct2cell(dot_acc_0); dot_acc_0 = dot_acc_0{1};
    all_arabic_acc_0(subj,:) = arabic_acc_0;
    all_dot_acc_0(subj,:) = dot_acc_0;

    arabic_acc_1 = struct2cell(arabic_acc_1); arabic_acc_1 = arabic_acc_1{1};
    dot_acc_1 = struct2cell(dot_acc_1); dot_acc_1 = dot_acc_1{1};
    all_arabic_acc_1(subj,:) = arabic_acc_1;
    all_dot_acc_1(subj,:) = dot_acc_1;

    arabic_acc_2 = struct2cell(arabic_acc_2); arabic_acc_2 = arabic_acc_2{1};
    dot_acc_2 = struct2cell(dot_acc_2); dot_acc_2 = dot_acc_2{1};
    all_arabic_acc_2(subj,:) = arabic_acc_2;
    all_dot_acc_2(subj,:) = dot_acc_2;

    arabic_acc_3 = struct2cell(arabic_acc_3); arabic_acc_3 = arabic_acc_3{1};
    dot_acc_3 = struct2cell(dot_acc_3); dot_acc_3 = dot_acc_3{1};
    all_arabic_acc_3(subj,:) = arabic_acc_3;
    all_dot_acc_3(subj,:) = dot_acc_3;

    arabic_acc_4 = struct2cell(arabic_acc_4); arabic_acc_4 = arabic_acc_4{1};
    dot_acc_4 = struct2cell(dot_acc_4); dot_acc_4 = dot_acc_4{1};
    all_arabic_acc_4(subj,:) = arabic_acc_4;
    all_dot_acc_4(subj,:) = dot_acc_4;

    arabic_acc_5 = struct2cell(arabic_acc_5); arabic_acc_5 = arabic_acc_5{1};
    dot_acc_5 = struct2cell(dot_acc_5); dot_acc_5 = dot_acc_5{1};
    all_arabic_acc_5(subj,:) = arabic_acc_5;
    all_dot_acc_5(subj,:) = dot_acc_5;


    clear arabic_conf dot_conf arabic_conf_tmp dot_conf_tmp
end

%% Compute Average Accuracies

mean_arabic_acc_0 = squeeze(mean(all_arabic_acc_0,1));
mean_dot_acc_0 = squeeze(mean(all_dot_acc_0,1));
arabicCI_0 = CalcCI95(all_arabic_acc_0);
dotCI_no0 = CalcCI95(all_dot_acc_0);

clear all_arabic_acc_0 all_dot_acc_0

mean_arabic_acc_1 = squeeze(mean(all_arabic_acc_1,1));
mean_dot_acc_1 = squeeze(mean(all_dot_acc_1,1));
arabicCI_1 = CalcCI95(all_arabic_acc_1);
dotCI_no1 = CalcCI95(all_dot_acc_1);

clear all_arabic_acc_1 all_dot_acc_1

mean_arabic_acc_2 = squeeze(mean(all_arabic_acc_2,1));
mean_dot_acc_2 = squeeze(mean(all_dot_acc_2,1));
arabicCI_2 = CalcCI95(all_arabic_acc_2);
dotCI_2 = CalcCI95(all_dot_acc_2);

clear all_arabic_acc_2 all_dot_acc_2

mean_arabic_acc_3 = squeeze(mean(all_arabic_acc_3,1));
mean_dot_acc_3 = squeeze(mean(all_dot_acc_3,1));
arabicCI_3 = CalcCI95(all_arabic_acc_3);
dotCI_3 = CalcCI95(all_dot_acc_3);

clear all_arabic_acc_3 all_dot_acc_3

mean_arabic_acc_4 = squeeze(mean(all_arabic_acc_4,1));
mean_dot_acc_4 = squeeze(mean(all_dot_acc_4,1));
arabicCI_4 = CalcCI95(all_arabic_acc_4);
dotCI_4 = CalcCI95(all_dot_acc_4);

clear all_arabic_acc_4 all_dot_acc_4

mean_arabic_acc_5 = squeeze(mean(all_arabic_acc_5,1));
mean_dot_acc_5 = squeeze(mean(all_dot_acc_5,1));
arabicCI_5 = CalcCI95(all_arabic_acc_5);
dotCI_5 = CalcCI95(all_dot_acc_5);

clear all_arabic_acc_5 all_dot_acc_5


all_arabic = {mean_arabic_acc_0; mean_arabic_acc_1; mean_arabic_acc_2; mean_arabic_acc_3;mean_arabic_acc_4;mean_arabic_acc_5};
all_dots = {mean_dot_acc_0;mean_dot_acc_1; mean_dot_acc_2; mean_dot_acc_3;mean_dot_acc_4;mean_dot_acc_5};
all_arabic_CI = {  arabicCI_0,arabicCI_1,arabicCI_2,arabicCI_3,arabicCI_4,arabicCI_5};
all_dot_CI = { dotCI_no0,dotCI_no1,dotCI_2,dotCI_3,dotCI_4,dotCI_5};
ci_colours = {[1,0,0],[1, 165/255, 0],[50/255, 205/255, 50/255],[0, 1, 1],[0, 0, 1],[1,0,1]};

figure;
subplot(1,2,1)
for num = 1:length(all_arabic)
    all_arabic_acc = all_arabic{num};
    mean_arabic_diag = all_arabic_acc';

    arabic_CIs = all_arabic_CI{num};

    upperCI = mean_arabic_diag+arabic_CIs;
    lowerCI = mean_arabic_diag-arabic_CIs;
    x = [arabic_time(1:5:length(arabic_time)), fliplr(arabic_time(1:5:length(arabic_time)))];
    inBetween = [upperCI(1:5:length(arabic_time)), fliplr(lowerCI(1:5:length(arabic_time)))];
    fill(x, inBetween,'b', 'FaceColor',ci_colours{num},'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');

    hold on;

    plot(arabic_time(1:5:length(arabic_time)),mean_arabic_diag(1:5:length(arabic_time)),'Color', ci_colours{num}, 'LineWidth', 1);
    xlim([arabic_time(1) arabic_time(end)]);
    ylim([0.4 1])
    title('Numerals');


    xlabel('Time (s)')
    ylabel('Discriminability (AUC)')

    hold on

end
yline(1/2,'--');

subplot(1,2,2)
for num = 1:length(all_dots)
    all_dot_acc = all_dots{num};
    mean_dot_diag = all_dot_acc';

    dot_CIs = all_dot_CI{num};

    upperCI = mean_dot_diag+dot_CIs;
    lowerCI = mean_dot_diag-dot_CIs;
    x = [dot_time(1:5:length(dot_time)), fliplr(dot_time(1:5:length(dot_time)))];
    inBetween = [upperCI(1:5:length(dot_time)), fliplr(lowerCI(1:5:length(dot_time)))];
    fill(x, inBetween,'b', 'FaceColor',ci_colours{num},'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');

    hold on;

    plot(dot_time(1:5:length(dot_time)),mean_dot_diag(1:5:length(dot_time)),'Color', ci_colours{num}, 'LineWidth', 1);
    xlim([dot_time(1) dot_time(end)]);
    ylim([0.4 1])
    title('Dots');


    xlabel('Time (s)')
    ylabel('Discriminability (AUC)')

    hold on
end
yline(1/2,'--');
legend('','Zero','','One','','Two','','Three','','Four','','Five');

