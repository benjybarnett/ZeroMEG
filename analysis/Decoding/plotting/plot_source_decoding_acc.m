clear;
close all;
subjects = {
    'sub001'
    'sub002' 
    'sub003'
    'sub004'
    'sub005'
    'sub006'
    %'sub007' %Removed for sleeping and 48% accuracy on arabic task
    'sub008'
    'sub009'
    'sub010'
    'sub011'

    };
timeon = 0;
timeoff = 0.5;
load('arabic_time.mat')
load('dot_time.mat')

%% Dots

fro_acc = [];
par_acc = [];

fro_conf = [];
par_conf = [];



for subj = 1:length(subjects)
    subject = subjects{subj};
    load(fullfile('D:\bbarnett\Documents\Zero\data\Analysis\MEG\Source\Decoding\dots\parietal\',subject,'results_2.mat'))
    acc = results{1}';
    par_acc = [par_acc; acc];
    par_conf(subj,:,:,:) = results{2};

    load(fullfile('D:\bbarnett\Documents\Zero\data\Analysis\MEG\Source\Decoding\dots\frontal\',subject,'results_2.mat'))
    acc = results{1}';
    fro_acc = [fro_acc; acc];
    fro_conf(subj,:,:,:) = results{2};
end

%Plot accuracies over time Parietal
mean_par = mean(par_acc);

std_dev = std(par_acc);
CIs = [];
for i =1:size(par_acc,2)

    sd = std_dev(i);
    n = size(par_acc,1);

    CIs(i) = 1.96*(sd/sqrt(n));
end


curve1 = mean_par+CIs;
curve2 =mean_par-CIs;
x2 = [dot_time, fliplr(dot_time)];

inBetween = [curve1, fliplr(curve2)];

figure;
fill(x2, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
hold on;
plot(dot_time, mean_par,'Color', '#0621A6', 'LineWidth', 1);
hold on;
xlim([dot_time(1) dot_time(end)]);
ylim([0.12 0.4])
yline(1/6,'--r');
xline(0,'--');
title('Dots - Parietal Decoding');
xlabel('Time (s)')
ylabel('Accuracy')

%Plot accuracy over time frontal
par_acc = fro_acc; %SAVING TIME EDITING PAR_ACC VARS BELOW
mean_par = mean(par_acc);

std_dev = std(par_acc);
CIs = [];
for i =1:size(par_acc,2)

    sd = std_dev(i);
    n = size(par_acc,1);

    CIs(i) = 1.96*(sd/sqrt(n));
end


curve1 = mean_par+CIs;
curve2 =mean_par-CIs;
x2 = [dot_time, fliplr(dot_time)];

inBetween = [curve1, fliplr(curve2)];

figure;
fill(x2, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
hold on;
plot(dot_time, mean_par,'Color', '#0621A6', 'LineWidth', 1);
hold on;
xlim([dot_time(1) dot_time(end)]);
ylim([0.12 0.4])
yline(1/6,'--r');
xline(0,'--');
title('Dots - Frontal Decoding');
xlabel('Time (s)')
ylabel('Accuracy')


%% Confusion Over Time

% Parietal
figure;
conf_grp = squeeze(mean(par_conf,1));
par_conf_grp = conf_grp;


time = dot_time(1:10:length(dot_time));
titles = {'P-Zero','P-One','P-Two','P-Three','P-Four','P-Five'};

for true_class = 1:size(conf_grp,2)
   
    
    %each loop will be a new plot
    %choose evry 10th element for smoothing
    zero = conf_grp(1:10:length(dot_time),true_class,1);
    one = conf_grp(1:10:length(dot_time),true_class,2);
    two = conf_grp(1:10:length(dot_time),true_class,3);
    three = conf_grp(1:10:length(dot_time),true_class,4);
    four = conf_grp(1:10:length(dot_time),true_class,5);
    five = conf_grp(1:10:length(dot_time),true_class,6);

    conditions = {zero; one;two; three;four;five};

    f = subplot(2,6,true_class);
   % f.Position = [200 300 250 350];
    
    curve1 = cell2mat(conditions(true_class))'+CIs(1:10:length(dot_time));
    curve2 =cell2mat(conditions(true_class))'-CIs(1:10:length(dot_time));
    x2 = [time, fliplr(time)];
    inBetween = [curve1, fliplr(curve2)];
    
    ci_colours = {[0, 0.4470, 0.7410],[0.8500, 0.3250, 0.0980],	[0.9290, 0.6940, 0.1250],[0.4940, 0.1840, 0.5560],'magenta','green'};		
    f = fill(x2, inBetween,cell2mat(ci_colours(true_class)),'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    f.Annotation.LegendInformation.IconDisplayStyle = 'off';
    hold on;
    chance = yline(1/6,'--','LineWidth', 1.4,'Color','black');
    chance.Annotation.LegendInformation.IconDisplayStyle = 'off';
    
    
    plot(time,zero,'Color',cell2mat(ci_colours(1)),'LineWidth',1.2);      
    plot(time,one,'Color',cell2mat(ci_colours(2)),'LineWidth',1.2);    
    plot(time,two,'Color',cell2mat(ci_colours(3)),'LineWidth',1.2); 
    plot(time,three,'Color',cell2mat(ci_colours(4)),'LineWidth',1.2);
    plot(time,four,'Color',cell2mat(ci_colours(5)),'LineWidth',1.2);
    plot(time,five,'Color',cell2mat(ci_colours(6)),'LineWidth',1.2);

    xlim([min(dot_time),max(dot_time)])
    ylim([0.08 0.5])
    
    if true_class == 1
        [pos,hobj,~,~] = legend('Zero', 'One', 'Two', 'Three','Four','Five');
        hl = findobj(hobj,'type','line');
        set(hl,'LineWidth',3);
        ht = findobj(hobj,'type','text');
        set(ht,'FontSize',6);
        set(ht,'FontName','Arial');
        set(pos,'position',[0.705 0.175 0.1 0.1])
    end
   
    xlabel('Time (seconds)','FontName','Arial')
    ylabel('Proportion Classified','FontName','Arial')
    title(titles(true_class),'FontName','Arial')
    %mkdir(fullfile(dir,'group',cfg.outputDir))
    %saveas(f,char(fullfile(dir,'group',cfg.outputDir,strcat(titles(true_class),'_diamonds.png'))))
end

% Frontal
conf_grp = squeeze(mean(fro_conf,1));
fro_conf_grp = conf_grp;

time = dot_time(1:10:length(dot_time));
titles = {'F-Zero','F-One','F-Two','F-Three','F-Four','F-Five'};

for true_class = 1:size(conf_grp,2)
   
    
    %each loop will be a new plot
    %choose evry 10th element for smoothing
    zero = conf_grp(1:10:length(dot_time),true_class,1);
    one = conf_grp(1:10:length(dot_time),true_class,2);
    two = conf_grp(1:10:length(dot_time),true_class,3);
    three = conf_grp(1:10:length(dot_time),true_class,4);
    four = conf_grp(1:10:length(dot_time),true_class,5);
    five = conf_grp(1:10:length(dot_time),true_class,6);

    conditions = {zero; one;two; three;four;five};

    f = subplot(2,6,true_class+6);
   % f.Position = [200 300 250 350];
    
    curve1 = cell2mat(conditions(true_class))'+CIs(1:10:length(dot_time));
    curve2 =cell2mat(conditions(true_class))'-CIs(1:10:length(dot_time));
    x2 = [time, fliplr(time)];
    inBetween = [curve1, fliplr(curve2)];
    
    ci_colours = {[0, 0.4470, 0.7410],[0.8500, 0.3250, 0.0980],	[0.9290, 0.6940, 0.1250],[0.4940, 0.1840, 0.5560],'magenta','green'};		
    f = fill(x2, inBetween,cell2mat(ci_colours(true_class)),'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    f.Annotation.LegendInformation.IconDisplayStyle = 'off';
    hold on;
    chance = yline(1/6,'--','LineWidth', 1.4,'Color','black');
    chance.Annotation.LegendInformation.IconDisplayStyle = 'off';
    
    
    plot(time,zero,'Color',cell2mat(ci_colours(1)),'LineWidth',1.2);      
    plot(time,one,'Color',cell2mat(ci_colours(2)),'LineWidth',1.2);    
    plot(time,two,'Color',cell2mat(ci_colours(3)),'LineWidth',1.2); 
    plot(time,three,'Color',cell2mat(ci_colours(4)),'LineWidth',1.2);
    plot(time,four,'Color',cell2mat(ci_colours(5)),'LineWidth',1.2);
    plot(time,five,'Color',cell2mat(ci_colours(6)),'LineWidth',1.2);

    xlim([min(dot_time),max(dot_time)])
    ylim([0.08 0.5])
    
    if true_class == 1
        [pos,hobj,~,~] = legend('Zero', 'One', 'Two', 'Three','Four','Five');
        hl = findobj(hobj,'type','line');
        set(hl,'LineWidth',3);
        ht = findobj(hobj,'type','text');
        set(ht,'FontSize',6);
        set(ht,'FontName','Arial');
        set(pos,'position',[0.705 0.175 0.1 0.1])
    end
   
    xlabel('Time (seconds)','FontName','Arial')
    ylabel('Proportion Classified','FontName','Arial')
    title(titles(true_class),'FontName','Arial')
    %mkdir(fullfile(dir,'group',cfg.outputDir))
    %saveas(f,char(fullfile(dir,'group',cfg.outputDir,strcat(titles(true_class),'_diamonds.png'))))
end



%% Plot confusion matrices averaged over timepoints

beg = find(dot_time == timeon);
fin =  find(dot_time == timeoff);

avg_conf = squeeze(mean(par_conf_grp(beg:fin,:,:),1));

%plot confusion matrix
figure;
subplot(1,2,1)
imagesc(avg_conf)
colormap(jet(512))
xtick = [0,1,2,3,4,5];
ytick = [0,1,2,3,4,5];
set(gca, 'XTick',xtick+1, 'XTickLabel',xtick,'YTickLabel',ytick)   
ylabel('True Class')
xlabel('Predicted Class')
a = colorbar;
a.Label.String = 'Proportion Classified';
    text(8,0.05,'DOTS - Parietal');

% Create MEG Tuning Curves
zero = avg_conf(:,1);
one = avg_conf(:,2);
two = avg_conf(:,3);
three = avg_conf(:,4);
four = avg_conf(:,5);
five = avg_conf(:,6);

curves = {zero one two three four five};

%plot
subplot(1,2,2)
x = [0 1 2 3 4 5];

colors = {'red','#FFA500','#32CD32','cyan','magenta','green'};
for cl = 1:length(curves)
    curve = curves{cl};
    plot(x,curve,'Color',colors{cl},'LineWidth' , 2)
    xticks([0 1 2 3 4 5]);
    ylabel('Prop. Predicted')
    xlabel('True Number')

    hold on
end
legend({'Zero' 'One' 'Two' 'Three' 'Four' 'Five'}); %true classes



%frontal

beg = find(dot_time == timeon);
fin =  find(dot_time == timeoff);

avg_conf = squeeze(mean(fro_conf_grp(beg:fin,:,:),1));

%plot confusion matrix
figure;
subplot(1,2,1)
imagesc(avg_conf)
colormap(jet(512))
xtick = [0,1,2,3,4,5];
ytick = [0,1,2,3,4,5];
set(gca, 'XTick',xtick+1, 'XTickLabel',xtick,'YTickLabel',ytick)   
ylabel('True Class')
xlabel('Predicted Class')
a = colorbar;
a.Label.String = 'Proportion Classified';
    text(8,0.05,'DOTS - FRONTAL');

% Create MEG Tuning Curves
zero = avg_conf(:,1);
one = avg_conf(:,2);
two = avg_conf(:,3);
three = avg_conf(:,4);
four = avg_conf(:,5);
five = avg_conf(:,6);

curves = {zero one two three four five};

%plot
subplot(1,2,2)
x = [0 1 2 3 4 5];

colors = {'red','#FFA500','#32CD32','cyan','magenta','green'};
for cl = 1:length(curves)
    curve = curves{cl};
    plot(x,curve,'Color',colors{cl},'LineWidth' , 2)
    xticks([0 1 2 3 4 5]);
    ylabel('Prop. Predicted')
    xlabel('True Number')

    hold on
end
legend({'Zero' 'One' 'Two' 'Three' 'Four' 'Five'}); %true classes







%% Arabic

fro_acc = [];
par_acc = [];

fro_conf = [];
par_conf = [];



for subj = 1:length(subjects)
    subject = subjects{subj};
    load(fullfile('D:\bbarnett\Documents\Zero\data\Analysis\MEG\Source\Decoding\arabic\parietal\',subject,'results.mat'))
    acc = results{1}';
    par_acc = [par_acc; acc];
    par_conf(subj,:,:,:) = results{2};

    load(fullfile('D:\bbarnett\Documents\Zero\data\Analysis\MEG\Source\Decoding\arabic\frontal\',subject,'results.mat'))
    acc = results{1}';
    fro_acc = [fro_acc; acc];
    fro_conf(subj,:,:,:) = results{2};
end

%Plot accuracies over time Parietal
mean_par = mean(par_acc);

std_dev = std(par_acc);
CIs = [];
for i =1:size(par_acc,2)

    sd = std_dev(i);
    n = size(par_acc,1);

    CIs(i) = 1.96*(sd/sqrt(n));
end


curve1 = mean_par+CIs;
curve2 =mean_par-CIs;
x2 = [arabic_time, fliplr(arabic_time)];

inBetween = [curve1, fliplr(curve2)];

figure;
fill(x2, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
hold on;
plot(arabic_time, mean_par,'Color', '#0621A6', 'LineWidth', 1);
hold on;
xlim([arabic_time(1) arabic_time(end)]);
ylim([0.12 0.4])
yline(1/6,'--r');
xline(0,'--');
title('Arabic - Parietal Decoding');
xlabel('Time (s)')
ylabel('Accuracy')

%Plot accuracy over time frontal
par_acc = fro_acc; %SAVING TIME EDITING PAR_ACC VARS BELOW
mean_par = mean(par_acc);

std_dev = std(par_acc);
CIs = [];
for i =1:size(par_acc,2)

    sd = std_dev(i);
    n = size(par_acc,1);

    CIs(i) = 1.96*(sd/sqrt(n));
end


curve1 = mean_par+CIs;
curve2 =mean_par-CIs;
x2 = [arabic_time, fliplr(arabic_time)];

inBetween = [curve1, fliplr(curve2)];

figure;
fill(x2, inBetween,'b', 'FaceColor','#F34C53','FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
hold on;
plot(arabic_time, mean_par,'Color', '#0621A6', 'LineWidth', 1);
hold on;
xlim([arabic_time(1) arabic_time(end)]);
ylim([0.12 0.4])
yline(1/6,'--r');
xline(0,'--');
title('Arabic - Frontal Decoding');
xlabel('Time (s)')
ylabel('Accuracy')


%% Confusion Over Time
figure;
% Parietal
conf_grp = squeeze(mean(par_conf,1));
par_conf_grp = conf_grp;

time = arabic_time(1:10:length(arabic_time));
titles = {'P-Zero','P-One','P-Two','P-Three','P-Four','P-Five'};

for true_class = 1:size(conf_grp,2)
   
    
    %each loop will be a new plot
    %choose evry 10th element for smoothing
    zero = conf_grp(1:10:length(arabic_time),true_class,1);
    one = conf_grp(1:10:length(arabic_time),true_class,2);
    two = conf_grp(1:10:length(arabic_time),true_class,3);
    three = conf_grp(1:10:length(arabic_time),true_class,4);
    four = conf_grp(1:10:length(arabic_time),true_class,5);
    five = conf_grp(1:10:length(arabic_time),true_class,6);

    conditions = {zero; one;two; three;four;five};

    f = subplot(2,6,true_class);
   % f.Position = [200 300 250 350];
    
    curve1 = cell2mat(conditions(true_class))'+CIs(1:10:length(arabic_time));
    curve2 =cell2mat(conditions(true_class))'-CIs(1:10:length(arabic_time));
    x2 = [time, fliplr(time)];
    inBetween = [curve1, fliplr(curve2)];
    
    ci_colours = {[0, 0.4470, 0.7410],[0.8500, 0.3250, 0.0980],	[0.9290, 0.6940, 0.1250],[0.4940, 0.1840, 0.5560],'magenta','green'};		
    f = fill(x2, inBetween,cell2mat(ci_colours(true_class)),'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    f.Annotation.LegendInformation.IconDisplayStyle = 'off';
    hold on;
    chance = yline(1/6,'--','LineWidth', 1.4,'Color','black');
    chance.Annotation.LegendInformation.IconDisplayStyle = 'off';
    
    
    plot(time,zero,'Color',cell2mat(ci_colours(1)),'LineWidth',1.2);      
    plot(time,one,'Color',cell2mat(ci_colours(2)),'LineWidth',1.2);    
    plot(time,two,'Color',cell2mat(ci_colours(3)),'LineWidth',1.2); 
    plot(time,three,'Color',cell2mat(ci_colours(4)),'LineWidth',1.2);
    plot(time,four,'Color',cell2mat(ci_colours(5)),'LineWidth',1.2);
    plot(time,five,'Color',cell2mat(ci_colours(6)),'LineWidth',1.2);

    xlim([min(arabic_time),max(arabic_time)])
    ylim([0.08 0.5])
    
    if true_class == 1
        [pos,hobj,~,~] = legend('Zero', 'One', 'Two', 'Three','Four','Five');
        hl = findobj(hobj,'type','line');
        set(hl,'LineWidth',3);
        ht = findobj(hobj,'type','text');
        set(ht,'FontSize',6);
        set(ht,'FontName','Arial');
        set(pos,'position',[0.705 0.175 0.1 0.1])
    end
   
    xlabel('Time (seconds)','FontName','Arial')
    ylabel('Proportion Classified','FontName','Arial')
    title(titles(true_class),'FontName','Arial')
    %mkdir(fullfile(dir,'group',cfg.outputDir))
    %saveas(f,char(fullfile(dir,'group',cfg.outputDir,strcat(titles(true_class),'_diamonds.png'))))
end




% Frontal
conf_grp = squeeze(mean(fro_conf,1));
fro_conf_grp = conf_grp;

time = arabic_time(1:10:length(arabic_time));
titles = {'F-Zero','F-One','F-Two','F-Three','F-Four','F-Five'};

for true_class = 1:size(conf_grp,2)
   
    
    %each loop will be a new plot
    %choose evry 10th element for smoothing
    zero = conf_grp(1:10:length(arabic_time),true_class,1);
    one = conf_grp(1:10:length(arabic_time),true_class,2);
    two = conf_grp(1:10:length(arabic_time),true_class,3);
    three = conf_grp(1:10:length(arabic_time),true_class,4);
    four = conf_grp(1:10:length(arabic_time),true_class,5);
    five = conf_grp(1:10:length(arabic_time),true_class,6);

    conditions = {zero; one;two; three;four;five};

    f = subplot(2,6,true_class+6);
   % f.Position = [200 300 250 350];
    
    curve1 = cell2mat(conditions(true_class))'+CIs(1:10:length(arabic_time));
    curve2 =cell2mat(conditions(true_class))'-CIs(1:10:length(arabic_time));
    x2 = [time, fliplr(time)];
    inBetween = [curve1, fliplr(curve2)];
    
    ci_colours = {[0, 0.4470, 0.7410],[0.8500, 0.3250, 0.0980],	[0.9290, 0.6940, 0.1250],[0.4940, 0.1840, 0.5560],'magenta','green'};		
    f = fill(x2, inBetween,cell2mat(ci_colours(true_class)),'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
    f.Annotation.LegendInformation.IconDisplayStyle = 'off';
    hold on;
    chance = yline(1/6,'--','LineWidth', 1.4,'Color','black');
    chance.Annotation.LegendInformation.IconDisplayStyle = 'off';
    
    
    plot(time,zero,'Color',cell2mat(ci_colours(1)),'LineWidth',1.2);      
    plot(time,one,'Color',cell2mat(ci_colours(2)),'LineWidth',1.2);    
    plot(time,two,'Color',cell2mat(ci_colours(3)),'LineWidth',1.2); 
    plot(time,three,'Color',cell2mat(ci_colours(4)),'LineWidth',1.2);
    plot(time,four,'Color',cell2mat(ci_colours(5)),'LineWidth',1.2);
    plot(time,five,'Color',cell2mat(ci_colours(6)),'LineWidth',1.2);

    xlim([min(arabic_time),max(arabic_time)])
    ylim([0.08 0.5])
    
    if true_class == 1
        [pos,hobj,~,~] = legend('Zero', 'One', 'Two', 'Three','Four','Five');
        hl = findobj(hobj,'type','line');
        set(hl,'LineWidth',3);
        ht = findobj(hobj,'type','text');
        set(ht,'FontSize',6);
        set(ht,'FontName','Arial');
        set(pos,'position',[0.705 0.175 0.1 0.1])
    end
   
    xlabel('Time (seconds)','FontName','Arial')
    ylabel('Proportion Classified','FontName','Arial')
    title(titles(true_class),'FontName','Arial')
    %mkdir(fullfile(dir,'group',cfg.outputDir))
    %saveas(f,char(fullfile(dir,'group',cfg.outputDir,strcat(titles(true_class),'_diamonds.png'))))
end


% Plot confusion matrices averaged over timepoints

beg = find(arabic_time == timeon);
fin =  find(arabic_time == timeoff);

avg_conf = squeeze(mean(par_conf_grp(beg:fin,:,:),1));

%plot confusion matrix
figure;
subplot(1,2,1)
imagesc(avg_conf)
colormap(jet(512))
xtick = [0,1,2,3,4,5];
ytick = [0,1,2,3,4,5];
set(gca, 'XTick',xtick+1, 'XTickLabel',xtick,'YTickLabel',ytick)   
ylabel('True Class')
xlabel('Predicted Class')
a = colorbar;
a.Label.String = 'Proportion Classified';
    text(8,0.05,'NUMERALS - Parietal');

% Create MEG Tuning Curves
zero = avg_conf(:,1);
one = avg_conf(:,2);
two = avg_conf(:,3);
three = avg_conf(:,4);
four = avg_conf(:,5);
five = avg_conf(:,6);

curves = {zero one two three four five};

%plot
subplot(1,2,2)
x = [0 1 2 3 4 5];

colors = {'red','#FFA500','#32CD32','cyan','magenta','green'};
for cl = 1:length(curves)
    curve = curves{cl};
    plot(x,curve,'Color',colors{cl},'LineWidth' , 2)
    xticks([0 1 2 3 4 5]);
    ylabel('Prop. Predicted')
    xlabel('True Number')

    hold on
end
legend({'Zero' 'One' 'Two' 'Three' 'Four' 'Five'}); %true classes

%frontal 
beg = find(arabic_time == timeon);
fin =  find(arabic_time == timeoff);

avg_conf = squeeze(mean(fro_conf_grp(beg:fin,:,:),1));

%plot confusion matrix
figure;
subplot(1,2,1)
imagesc(avg_conf)
colormap(jet(512))
xtick = [0,1,2,3,4,5];
ytick = [0,1,2,3,4,5];
set(gca, 'XTick',xtick+1, 'XTickLabel',xtick,'YTickLabel',ytick)   
ylabel('True Class')
xlabel('Predicted Class')
a = colorbar;
a.Label.String = 'Proportion Classified';
    text(8,0.05,'NUMERALS - Frontal');

% Create MEG Tuning Curves
zero = avg_conf(:,1);
one = avg_conf(:,2);
two = avg_conf(:,3);
three = avg_conf(:,4);
four = avg_conf(:,5);
five = avg_conf(:,6);

curves = {zero one two three four five};

%plot
subplot(1,2,2)
x = [0 1 2 3 4 5];

colors = {'red','#FFA500','#32CD32','cyan','magenta','green'};
for cl = 1:length(curves)
    curve = curves{cl};
    plot(x,curve,'Color',colors{cl},'LineWidth' , 2)
    xticks([0 1 2 3 4 5]);
    ylabel('Prop. Predicted')
    xlabel('True Number')

    hold on
end
legend({'Zero' 'One' 'Two' 'Three' 'Four' 'Five'}); %true classes


