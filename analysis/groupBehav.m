function groupBehav(curves,meanRTs)


    %% Dots

    groupCurves = squeeze(mean(reshape(cell2mat(curves),[6,6,length(curves)]),3));
    %Plot Tuning Curve
    figure;
    x = [0 1 2 3 4 5];
    colors = {'red','#FFA500','#32CD32','cyan','blue','magenta'};
    for c = 1:length(groupCurves)
        curve = groupCurves(c,:);
        plot(x,curve,'Color',colors{c},'LineWidth' , 1.2)
        xticks([0 1 2 3 4 5]);
        ylabel('% same as sample')
        xlabel('Test Numerosity')
        hold on
    end
    legend({'Zero' 'One' 'Two' 'Three' 'Four' 'Five'});
    title('Group Behavioural Tuning Curves')
    
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

end