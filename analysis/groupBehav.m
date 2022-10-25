function groupBehav(d,cr,md,curves)


    %% Number

    groupCurves = squeeze(mean(reshape(cell2mat(curves),[4,4,4]),3));
    %Plot Group
    figure;
    x = [0 1 2 3];
    colors = {'red','#FFA500','#32CD32','cyan'};
    for c = 1:length(groupCurves)
        curve = groupCurves(c,:);
        plot(x,curve,'Color',colors{c},'LineWidth' , 1.2)
        xticks([0 1 2 3]);
        ylabel('% same as sample')
        xlabel('Test Numerosity')
        hold on
    end
    legend({'Zero' 'One' 'Two' 'Three'});

    %% Detection
    grpD = mean(cell2mat(d));
    grpC = mean(cell2mat(cr));
    grpMD = mean(cell2mat(md));
    seD = std(cell2mat(d)) / sqrt( length( cell2mat(d) ));
    seC= std(cell2mat(cr)) / sqrt( length( cell2mat(cr) ));
    seMD= std(cell2mat(md)) / sqrt( length( cell2mat(md) ));
    


    means = [grpC, grpD, grpMD];
    se = [seC,seD,seMD];
    labels = categorical({'d-prime', 'Criterion','Meta-d'''});
    labels = reordercats(labels,{'Criterion','d-prime', 'Meta-d'''});
    disp(means)
    disp(se)
    figure;
    x = 1:3;
    data = means';
     
    b = bar(x,data) ;               
    hold on
    
    er = errorbar(x,data,se);    
    er.Color = [0 0 0];                            
    er.LineStyle = 'none';  
    xticklabels({'Criterion' 'D-prime' 'Meta-d'''})
    hold off
end