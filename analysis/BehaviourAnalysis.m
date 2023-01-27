function [curves,meanRTs] = BehaviourAnalysis(cfg0,subject)

    %% Load Data
    load(fullfile(cfg0.root,subject,'meg','trial_data','data.mat'));
    fprintf('Analysing %ss'' behavioural data...\n\n',subject);
    

    %% Output Directory
    outputDir = fullfile('D:\bbarnett\Documents\Zero\data\Analysis\Behav\',subject);
    if ~isdir(outputDir)
        mkdir(outputDir)
    end

    %% Split Tasks
    arb_data = data(data(:,3) == 2,:);
    num_data = data(data(:,3) == 1,:);
    
    %% Arabic Analysis
    disp('ARABIC TASK')
    %trials missed
    missed = sum(arb_data(:,24)== 0|arb_data(:,24)==9)/(length(arb_data))*100;
    fprintf('%s missed %.2f%% of arabic trials.\n', subject,missed);
    %Accuracy
    perc_corr = sum(arb_data(:,26),'omitnan')/(length(arb_data))*100;
    fprintf('%s got %.2f%% correct in the arabic task.\n', subject,perc_corr);
    %Proportion of Blue/Orange
    blue = arb_data(arb_data(:,24) == 1,:);
    propBlue = (length(blue)/length(arb_data))*100;
    orange = arb_data(arb_data(:,24) == 2,:);
    propOrange =  (length(orange)/length(arb_data))*100;
    fprintf('%s has these proportions of colour responses: \n %.2f%% Blue \n %.2f%% Orange\n',...
        subject,propBlue,propOrange)

    %% Numerical Match to Sample
    disp('NUMERICAL TASK')
    %trials missed
    missed = sum(num_data(:,31)==0|num_data(:,31)==9)/(length(num_data))*100;
    fprintf('%s missed %.2f%% of dot trials.\n', subject,missed);
    %Accuracy
    perc_corr = sum(num_data(:,33),'omitnan')/(length(num_data))*100;
    fprintf('%s got %.2f%% correct.\n', subject,perc_corr);

    %proportion of Same/Different Responses
    same = num_data(num_data(:,31) == 1,:);
    propSame = (length(same)/length(num_data))*100;
    different = num_data(num_data(:,31) == 2,:);
    propDifferent =  (length(different)/length(num_data))*100;

    fprintf('%s has these proportions of numerical responses: \n %.2f%% Same \n %.2f%% Different\n',...
        subject,propSame,propDifferent)

    props = [propSame,propDifferent];
    labels = categorical({'Same', 'Different'});
    labels = reordercats(labels,{'Same', 'Different'});
    if cfg0.plot
    figure;
    bar(labels,props,'FaceAlpha',0.3,'FaceColor', [1 0 0],'EdgeColor','None');
    ylabel('Percentage trials responded')
    ylim([0 70])
    end

    %Tuning curves
    [zero_incorrect,one_incorrect,two_incorrect,three_incorrect,four_incorrect,five_incorrect] = GetIncorrects(num_data);
    [zero_correct,one_correct,two_correct,three_correct,four_correct,five_correct] = GetCorrects(num_data);
    zero_curve = [zero_correct,zero_incorrect];
    one_curve = [one_incorrect(1),one_correct,one_incorrect(2:end)];
    two_curve = [two_incorrect(1:2),two_correct,two_incorrect(3:end)];
    three_curve = [three_incorrect(1:3),three_correct,three_incorrect(4:end)];
    four_curve = [four_incorrect(1:4),four_correct,four_incorrect(5)];
    five_curve = [five_incorrect,five_correct];

    curves = {zero_curve one_curve two_curve three_curve four_curve five_curve};
    
    %RTs
    [meanRTs,sdRTs] = GetRTs(num_data);

    %plot
    if cfg0.plot
    figure;
    x = [0 1 2 3 4 5];
 
    colors = {'red','#FFA500','#32CD32','cyan','blue','magenta'};
    for cl = 1:length(curves)
        curve = curves{cl};
        plot(x,curve,'Color',colors{cl},'LineWidth' , 1.2)
        xticks([0 1 2 3 4 5]);
        ylabel('% same as sample')
        xlabel('Test Numerosity')
        
        hold on
    end
   % legend({'Zero' 'One' 'Two' 'Three' 'Four' 'Five'});
    saveas(gcf,fullfile(outputDir,'numerical.png'))
    
   
   
    %RTs as distance between sample and test differs
    figure;
    x =0:length(meanRTs)-1;
    bar(x,meanRTs);
    hold on
    er = errorbar(x,meanRTs,sdRTs,sdRTs);    
    er.Color = [0 0 0];                            
    er.LineStyle = 'none';  

    hold off
    xlabel('Distance between sample and test number')
    ylabel('Mean RT (secs)')
    end

     %return
    curves = [zero_curve; one_curve; two_curve; three_curve; four_curve; five_curve];
end