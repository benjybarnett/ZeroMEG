function groupBehav(curves,meanRTs,dot_acc,arabic_acc)


    %% Dots

    groupCurves = squeeze(nanmean(reshape(cell2mat(curves),[6,6,length(curves)]),3));

    curveSEs = squeeze(nanstd(reshape(cell2mat(curves),[6,6,length(curves)]),0,3))/sqrt(length(curves));

    %Plot Tuning Curve
    figure;
    x = [0 1 2 3 4 5];
    colors = {'red','#FFA500','#32CD32','cyan','blue','magenta'};
    for c = 1:length(groupCurves)
        curve = groupCurves(c,:);
        se = curveSEs(c,:);
        errorbar(x,curve,se,'Color',colors{c},'LineWidth' , 2.5)
        xticks([0 1 2 3 4 5]);
        ylabel('% same as sample')
        xlabel('Test Numerosity')
        hold on
    end
    legend({'Zero' 'One' 'Two' 'Three' 'Four' 'Five'},'Location','bestoutside');
    %title('Group Behavioural Tuning Curves')
    set(gca,"FontSize",20)
    %% Accuracy

    mean_arabic_acc = mean(cell2mat(arabic_acc));
    higher_acc = [];
    lower_acc = [];
    for i = 1:length(arabic_acc)
        sub = subjects{i};
        if mod(sub(end),2)
            lower_acc = [lower_acc cell2mat(arabic_acc(i))];
        else
            higher_acc = [higher_acc cell2mat(arabic_acc(i))];
        end
    end
    mean_higher_acc = mean(higher_acc);
    mean_lower_acc = mean(lower_acc);
    mean_dot_acc = mean(cell2mat(dot_acc));
    accs = [mean_lower_acc,mean_higher_acc];

    se_lower = std(lower_acc)/sqrt(length(lower_acc));
    se_higher = std(higher_acc)/sqrt(length(higher_acc));

    se_dot = std(cell2mat(dot_acc))/sqrt(length(dot_acc));
    ses = [se_lower, se_higher];
    x = 1:2;
    figure;
    b = bar(x,accs);
    b(1).FaceColor = '#218380';
    b(1).FaceColor = '#74226C';
    hold on

    er = errorbar(x,accs,ses);  
    er.Color = [0 0 0];                            
    er.LineStyle = 'none';
    er.LineWidth = 2;
    ylabel('Accuracy (%)')
    xticklabels({'Lower','Higher'})
    set(gca,'FontSize', 20)
    
    %{
    %RTs
    group_RTs = squeeze(mean(reshape(cell2mat(meanRTs),[1,6,length(meanRTs)]),3));
    SEs = squeeze(std(reshape(cell2mat(meanRTs),[1,6,length(meanRTs)]),0,3)) /sqrt(length(meanRTs));

    figure;
    x =0:length(group_RTs)-1;
    bar(x,group_RTs);
    hold on
    er = errorbar(x,group_RTs,SEs,SEs);    
    er.Color = [0 0 0];                            
    er.LineStyle = 'none';  

    hold off
    xlabel('Distance between sample and test number')
    ylabel('Mean RT (secs)')
    title('Group RTs per Distance')
    %}


    four = [];
    three = [];

    for subj = 1:length(subjects)
        ds = subjCurves{subj};
        four = [four ds(6,5)];
        three = [three ds(6,4)];
    end

end