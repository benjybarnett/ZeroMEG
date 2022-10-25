function [dprime,c,meta_d,curves] = BehaviourAnalysis(cfg0,subject)

    %% Load Data
    load(fullfile(cfg0.root,subject,'meg','trial_data','data.mat'));
    fprintf('Analysing %ss'' behavioural data...\n\n',subject);
    
    staircase_data = load(fullfile(cfg0.root,subject,'detection_staircase','results_staircase.mat'));

    %% Output Directory
    outputDir = fullfile('D:\bbarnett\Documents\Zero\data\Analysis\Behav\',subject);
    if ~isdir(outputDir)
        mkdir(outputDir)
    end

    %% Initial Staircase Procedure
     %plot staircase values
    houseVisibility = staircase_data.results.detection.houses.visibility;
    faceVisibility = staircase_data.results.detection.faces.visibility;
    
    figure;
    x = 1:1:length(houseVisibility);
    plot(x,houseVisibility);
    hold on
    plot(x,faceVisibility);
    ylim([0,1]);
    xlim([min(x),max(x)])
    title('Staircasing Block')
    ylabel('Visibility Parameter')
    xlabel('Trials')
    legend('House Visibility','Face Visibility')

    %% Split Tasks
    det_data = data(data(:,3) == 2,:);
    num_data = data(data(:,3) == 1,:);
    
    %% Detection Analysis
    disp('DETECTION TASK')
    %percent trials no detection response
    perc_noResp =( length(det_data(det_data(:,7) == 0 | det_data(:,7) == 9))/length(det_data))*100;
    %percent trials no confidence response
    perc_noConf = ( length(det_data(det_data(:,10) == 0 | det_data(:,10) == 9))/length(det_data))*100;
    fprintf('%s did not make a detection response in %.2f%% of trials \nand did not make a confidence response in %.2f%% of trials\n', subject,perc_noResp,perc_noConf);

    %percent correct
    perc_corr_face = sum(det_data(det_data(:,4)==2,9),'omitnan')/(length(det_data)/2)*100;
    perc_corr_house = sum(det_data(det_data(:,4)==1,9),'omitnan')/(length(det_data)/2)*100;

    fprintf('%s got %.2f%% correct in house trials and %.2f%% in face trials.\n', subject,perc_corr_house, perc_corr_face);
    
    %proportion of Absent low/high conf // present low/high conf
    absLow = det_data(det_data(:,7) == 2 & det_data(:,10) == 1,:);
    propAbsLow = (length(absLow)/length(det_data))*100;
    absHigh = det_data(det_data(:,7) == 2 & det_data(:,10) == 2);
    propAbsHigh = (length(absHigh)/length(det_data))*100;
    presLow = det_data(det_data(:,7) == 1 & det_data(:,10) == 1);
    propPresLow = (length(presLow)/length(det_data))*100;
    presHigh = det_data(det_data(:,7) == 1 & det_data(:,10) == 2);
    propPresHigh = (length(presHigh)/length(det_data))*100;
    
    fprintf('%s has these proportions of detection responses: \n %.2f%% Absent-Low \n %.2f%% Absent-High \n %.2f%% Present-Low \n %.2f%% Present-High\n',...
        subject,propAbsLow,propAbsHigh,propPresLow,propPresHigh)

    props = [propAbsHigh, propAbsLow, propPresLow, propPresHigh];
    labels = categorical({'Absent-High', 'Absent-Low','Present-Low','Present-High'});
    labels = reordercats(labels,{'Absent-High', 'Absent-Low','Present-Low','Present-High'});
    figure;
    bar(labels,props,'FaceAlpha',0.3,'FaceColor', [1 0 0],'EdgeColor','None');
    ylabel('Percentage trials responded');
    ylim([0 70])

    %M_ratio
    corrPresHigh = length(det_data(det_data(:,7) == 1 & det_data(:,10) == 2 & det_data(:,9) == 1));
    corrPresLow =  length(det_data(det_data(:,7) == 1 & det_data(:,10) == 1 & det_data(:,9) == 1));
    incorrAbsLow =  length(det_data(det_data(:,7) == 2 & det_data(:,10) == 1 & det_data(:,9) == 0));
    incorrAbsHigh =  length(det_data(det_data(:,7) == 2 & det_data(:,10) == 2 & det_data(:,9) == 0));
    
    incorrPresHigh = length(det_data(det_data(:,7) == 1 & det_data(:,10) == 2 & det_data(:,9) == 0));
    incorrPresLow =  length(det_data(det_data(:,7) == 1 & det_data(:,10) == 1 & det_data(:,9) == 0));
    corrAbsLow = length( det_data(det_data(:,7) == 2 & det_data(:,10) == 1 & det_data(:,9) == 1));
    corrAbsHigh =  length(det_data(det_data(:,7) == 2 & det_data(:,10) == 2 & det_data(:,9) == 1));
    
    nR_present = [ corrPresHigh, corrPresLow, incorrAbsLow, incorrAbsHigh];
    nR_absent = [incorrPresHigh, incorrPresLow, corrAbsLow, corrAbsHigh];
 
    stats = fit_meta_d_MLE(nR_present,nR_absent);
    
    dprime = stats.d1;
    c = stats.c1;
    meta_d = stats.meta_d;
    mRatio = stats.M_ratio;
    
    fprintf('\nD'' = %.2f, C = %.2f, Meta-D'' = %.2f, M-Ratio = %.2f \n', ...
        dprime,c,meta_d,mRatio);
    
    %plot staircase values
    houseVisibility = det_data(det_data(:,4) == 1,6);
    faceVisibility = det_data(det_data(:,4) == 2,6);
    
    figure;
    x = 1:1:length(houseVisibility);
    plot(x,houseVisibility);
    hold on
    plot(x,faceVisibility);
    ylim([0,1]);
    xlim([min(x),max(x)])
    title('Experimental Blocks')
    ylabel('Visibility Parameter')
    xlabel('Trials')
    legend('House Visibility','Face Visibility')

    saveas(gcf,fullfile(outputDir,'staircase.png'))
    
    %% Numerical Match to Sample
    disp('NUMERICAL TASK')
    %trials missed
    missed = sum(num_data(:,17)==0|num_data(:,17)==9)/(length(num_data))*100;
    fprintf('%s missed %.2f%% of trials.\n', subject,missed);
    %Accuracy
    perc_corr = sum(num_data(:,19),'omitnan')/(length(num_data))*100;
    fprintf('%s got %.2f%% correct.\n', subject,perc_corr);

    %proportion of Same/Different Responses
    same = num_data(num_data(:,17) == 1,:);
    propSame = (length(same)/length(num_data))*100;
    different = num_data(num_data(:,17) == 2,:);
    propDifferent =  (length(different)/length(num_data))*100;

    fprintf('%s has these proportions of numerical responses: \n %.2f%% Same \n %.2f%% Different\n',...
        subject,propSame,propDifferent)

    props = [propSame,propDifferent];
    labels = categorical({'Same', 'Different'});
    labels = reordercats(labels,{'Same', 'Different'});
    figure;
    bar(labels,props,'FaceAlpha',0.3,'FaceColor', [1 0 0],'EdgeColor','None');
    ylabel('Percentage trials responded')
    ylim([0 70])

    %Tuning curves
    [zero_incorrect,one_incorrect,two_incorrect,three_incorrect] = GetIncorrects(num_data);
    [zero_correct,one_correct,two_correct,three_correct] = GetCorrects(num_data);
    zero_curve = [zero_correct,zero_incorrect];
    one_curve = [one_incorrect(1),one_correct,one_incorrect(2:end)];
    two_curve = [two_incorrect(1:2),two_correct,two_incorrect(3:end)];
    three_curve = [three_incorrect,three_correct];
    curves = {zero_curve one_curve two_curve three_curve};
    
    %plot
    figure;
    x = [0 1 2 3];
 
    colors = {'red','#FFA500','#32CD32','cyan'};
    for cl = 1:length(curves)
        curve = curves{cl};
        plot(x,curve,'Color',colors{cl},'LineWidth' , 1.2)
        xticks([0 1 2 3]);
        ylabel('% same as sample')
        xlabel('Test Numerosity')
        
        hold on
    end
    legend({'Zero' 'One' 'Two' 'Three'});
    saveas(gcf,fullfile(outputDir,'numerical.png'))
    
    %return
    curves = [zero_curve; one_curve; two_curve; three_curve];
   
   
end