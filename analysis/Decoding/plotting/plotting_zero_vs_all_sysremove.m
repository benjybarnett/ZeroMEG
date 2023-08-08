%% Plot accuracies when removing each numerosity systematically
    if cfg0.sysRemove
        for subj =1:length(subjects)
            subject = subjects{subj};
            disp(subject)
    
            if strcmp(cfg0.decoding_type,'cross')
                dot_time = arabic_time;
                %Accuracy
                arabic_acc_no1 = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_arabic_acc_no_1.mat'));
                dot_acc_no1 = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_dot_acc_no_1.mat'));
                arabic_acc_no2 = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_arabic_acc_no_2.mat'));
                dot_acc_no2 = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_dot_acc_no_2.mat'));
                arabic_acc_no3 = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_arabic_acc_no_3.mat'));
                dot_acc_no3 = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_dot_acc_no_3.mat'));
                arabic_acc_no4 = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_arabic_acc_no_4.mat'));
                dot_acc_no4 = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_dot_acc_no_4.mat'));
                arabic_acc_no5 = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_arabic_acc_no_5.mat'));
                dot_acc_no5 = load(fullfile(cfg0.root,cfg0.output_path,subject,'train_dot_acc_no_5.mat'));
            elseif strcmp(cfg0.decoding_type,'within')
                arabic_acc_no1 = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_arabic_acc_no_1.mat'));
                dot_acc_no1 = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_dot_acc_no_1.mat'));
                arabic_acc_no2 = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_arabic_acc_no_2.mat'));
                dot_acc_no2 = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_dot_acc_no_2.mat'));
                arabic_acc_no3 = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_arabic_acc_no_3.mat'));
                dot_acc_no3 = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_dot_acc_no_3.mat'));
                arabic_acc_no4 = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_arabic_acc_no_4.mat'));
                dot_acc_no4 = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_dot_acc_no_4.mat'));
                arabic_acc_no5 = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_arabic_acc_no_5.mat'));
                dot_acc_no5 = load(fullfile(cfg0.root,cfg0.output_path,subject,'within_dot_acc_no_5.mat'));
            
            else
                warning('Decoding Type Not Recognised');
            end
            
            %Group Accuracies
            arabic_acc_no1 = struct2cell(arabic_acc_no1); arabic_acc_no1 = arabic_acc_no1{1};
            dot_acc_no1 = struct2cell(dot_acc_no1); dot_acc_no1 = dot_acc_no1{1};
            all_arabic_acc_no1(subj,:,:) = diag(arabic_acc_no1);
            all_dot_acc_no1(subj,:,:) = diag(dot_acc_no1);
    
            arabic_acc_no2 = struct2cell(arabic_acc_no2); arabic_acc_no2 = arabic_acc_no2{1};
            dot_acc_no2 = struct2cell(dot_acc_no2); dot_acc_no2 = dot_acc_no2{1};
            all_arabic_acc_no2(subj,:,:) = diag(arabic_acc_no2);
            all_dot_acc_no2(subj,:,:) = diag(dot_acc_no2);
            
            arabic_acc_no3 = struct2cell(arabic_acc_no3); arabic_acc_no3 = arabic_acc_no3{1};
            dot_acc_no3 = struct2cell(dot_acc_no3); dot_acc_no3 = dot_acc_no3{1};
            all_arabic_acc_no3(subj,:,:) = diag(arabic_acc_no3);
            all_dot_acc_no3(subj,:,:) = diag(dot_acc_no3);
            
            arabic_acc_no4 = struct2cell(arabic_acc_no4); arabic_acc_no4 = arabic_acc_no4{1};
            dot_acc_no4 = struct2cell(dot_acc_no4); dot_acc_no4 = dot_acc_no4{1};
            all_arabic_acc_no4(subj,:,:) = diag(arabic_acc_no4);
            all_dot_acc_no4(subj,:,:) = diag(dot_acc_no4);
    
            arabic_acc_no5 = struct2cell(arabic_acc_no5); arabic_acc_no5 = arabic_acc_no5{1};
            dot_acc_no5 = struct2cell(dot_acc_no5); dot_acc_no5 = dot_acc_no5{1};
            all_arabic_acc_no5(subj,:,:) = diag(arabic_acc_no5);
            all_dot_acc_no5(subj,:,:) = diag(dot_acc_no5);

    
            clear arabic_conf dot_conf arabic_conf_tmp dot_conf_tmp
        end
        
        %% Compute Average Accuracies

       % clear all_arabic_acc_no0 all_dot_acc_no0

        mean_arabic_acc_no1 = squeeze(mean(all_arabic_acc_no1,1));
        mean_dot_acc_no1 = squeeze(mean(all_dot_acc_no1,1));
        arabicCI_no1 = CalcCI95(all_arabic_acc_no1);
        dotCI_no1 = CalcCI95(all_dot_acc_no1);

        clear all_arabic_acc_no1 all_dot_acc_no1

        mean_arabic_acc_no2 = squeeze(mean(all_arabic_acc_no2,1));
        mean_dot_acc_no2 = squeeze(mean(all_dot_acc_no2,1));
        arabicCI_no2 = CalcCI95(all_arabic_acc_no2);
        dotCI_no2 = CalcCI95(all_dot_acc_no2);

        clear all_arabic_acc_no2 all_dot_acc_no2

        mean_arabic_acc_no3 = squeeze(mean(all_arabic_acc_no3,1));
        mean_dot_acc_no3 = squeeze(mean(all_dot_acc_no3,1));
        arabicCI_no3 = CalcCI95(all_arabic_acc_no3);
        dotCI_no3 = CalcCI95(all_dot_acc_no3);

        clear all_arabic_acc_no3 all_dot_acc_no3

        mean_arabic_acc_no4 = squeeze(mean(all_arabic_acc_no4,1));
        mean_dot_acc_no4 = squeeze(mean(all_dot_acc_no4,1));
        arabicCI_no4 = CalcCI95(all_arabic_acc_no4);
        dotCI_no4 = CalcCI95(all_dot_acc_no4);

        clear all_arabic_acc_no4 all_dot_acc_no4

        mean_arabic_acc_no5 = squeeze(mean(all_arabic_acc_no5,1));
        mean_dot_acc_no5 = squeeze(mean(all_dot_acc_no5,1));
        arabicCI_no5 = CalcCI95(all_arabic_acc_no5);
        dotCI_no5 = CalcCI95(all_dot_acc_no5);

        clear all_arabic_acc_no5 all_dot_acc_no5


        all_arabic = {mean_arabic_acc_no1; mean_arabic_acc_no2; mean_arabic_acc_no3;mean_arabic_acc_no4;mean_arabic_acc_no5};
        all_dots = {mean_dot_acc_no1; mean_dot_acc_no2; mean_dot_acc_no3;mean_dot_acc_no4;mean_dot_acc_no5};
        all_arabic_CI = { arabicCI_no1,arabicCI_no2,arabicCI_no3,arabicCI_no4,arabicCI_no5};
        all_dot_CI = { dotCI_no1,dotCI_no2,dotCI_no3,dotCI_no4,dotCI_no5};
        ci_colours = {[1, 165/255, 0],[50/255, 205/255, 50/255],[0, 1, 1],[0, 0, 1],[1,0,1]};		

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
            ylim([0.4 0.9])
            title('Train on Numerals');
            

            xlabel('Time (s)')
            ylabel('Accuracy')

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
            ylim([0.4 0.8])
            title('Train on Dots');
            

            xlabel('Time (s)')
            ylabel('Accuracy')

            hold on
        end
        yline(1/2,'--');
        legend('','No One','','No Two','','No Three','','No Four','','No Five');

    end