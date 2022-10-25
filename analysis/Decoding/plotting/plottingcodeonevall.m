 %% Test Best Decoders on New Domain
    figure('units','normalized','outerposition',[0 0 1 1]);
    colours = {[0, 0.4470, 0.7410],[0.8500, 0.3250, 0.0980],[0.9290, 0.6940, 0.1250],[0.4940, 0.1840, 0.5560]};		
    class_names = {'Zero','One','Two','Three'};
    for clf = 1:length(best_decoders)
        subplot(2,4,clf)
        fprintf('Using Decoder %d of %d \n',clf,length(best_decoders))
        decoder = best_decoders{clf};
        test_dvals ={};
        for test_class = 1:length(classes)
            %Select only 1 test class at a time
            data = smoothed_det_data(det_labels==test_class,:,:);
            fprintf('Decoding class %d of %d \n',test_class,length(classes))
            dvals_x_time = [];
            for t = 1:size(data,3)
                dvals = mv_get_classifier_output('dval',decoder,@test_lda,data(:,:,t));
                av_dval = -mean(dvals,1); %average probability of all trials
                dvals_x_time(:,t)= av_dval;
                %confidence intervals
                CI = CalcCI95(dvals);            
                CIs(:,t) = CI;
            end
            test_dvals{test_class} = dvals_x_time;
            ax = plot(time,test_dvals{test_class},'Color',cell2mat(colours(test_class)),'LineWidth',1.2);
            hold on;
            upperCI = test_dvals{test_class}+CIs;
            lowerCI = test_dvals{test_class}-CIs; 
            x = [time, fliplr(time)];
            inBetween = [upperCI, fliplr(lowerCI)];
            
            f = fill(x, inBetween,cell2mat(colours(test_class)),'FaceAlpha','0.2','EdgeAlpha','0.2','EdgeColor','none');
            ylabel('Classifier Evidence (AU)')
            xlabel('Time (Seconds)')
            set(gca,'YTick',[]); %which will get rid of all the markings for the y axis
            title([class_names{clf},' ','Decoder'])
    
            hold on;
            
        end
        ylim([min([test_dvals{:}])-std([test_dvals{:}]) max([test_dvals{:}])+std([test_dvals{:}])])
    
        if clf == 1
            legend('Zero','','One','','Two','','Three','Location','southeast')
        end
        hold off;
        
    
    
    end