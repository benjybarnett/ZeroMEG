

classifiers = {'House' 'Face' 'Nothing' 'Zero' 'One' 'Two' 'Three'};
for c = 1:length(classifiers)
    classifier = classifiers{c};
    lambdas = [0.00001,0.0001,0.001,0.005,0.01,0.05,0.1,0.125,0.15,0.175,0.2];
    for lam = 1:length(lambdas)
         lambda = lambdas(lam);
        %Binarise classes
        labels = data.trialinfo(:,stimIdx)==c;%labels is a Ntrials length vector with 1 for one class and 0 for the others
        
        %balance the number of trials of each condition
        idx = balance_trials(data.trialinfo(:,stimIdx),'downsample vs all',y_binary=double(labels)+1); %idx is a Nclass x 1 cell, each cell with [Ntrials x 1] containing indices for trials of particular classs
        
        Y = labels(cell2mat(idx));
        X = data.trial(cell2mat(idx),:,:);
        
        if size(X,1) == 0
            num_trials = 0;
            return
        end
        
        % check for NaNs
        nan_chidx = isnan(squeeze(X(1,:,1)));
        if sum(nan_chidx) > 0 
            fprintf('The following channels are NaNs, removing these \n');
            disp(data.label(nan_chidx));
            X(:,nan_chidx,:) = [];
        end
        
        fprintf('Using %d trials per class \n',sum(Y==1))
        num_trials = sum(Y==1);
        
         % n-fold cross-validation 
        folds = createFolds(cfg0,Y); %returns cell array of length nFolds that contains in each cell indices of the trials belong to that particular fold
        nTrials = size(X,1); nSamples = size(X,3);
        Betas = zeros(nSamples,nTrials);
        yhatBinom  = nan(nTrials,nSamples); 
        for f = 1:cfg0.nFold
            trainidx = setdiff(1:nTrials,folds{f}); %return indices of trials not in fold - used for training
            testidx = folds{f}; %return indices of trials in fold - used for testing
            x{1} = X(trainidx,:,:); x{2} = X(testidx,:,:); %split training and testing data into two cells in one cell array
            y{1} = Y(trainidx); y{2} = Y(testidx); %split training and testing labels into two cells in one cell array
            
            fprintf('Decoding fold %d out of %d \n',f,cfg0.nFold)
            %Xhat(:,testidx) = decodingDiag(cfg0,x,y); %decode here
            
            nSamplesTrain = size(x{1},3);
            nTrialsTest   = size(x{2},1);
            
            %Betas          = zeros(nSamplesTrain,nTrialsTest);
        
            nMeanS        = cfg.nMeanS;
            
            
            for s1 = 1:nSamplesTrain
                
                %add smoothing somewhere on this script
                
                if mod(s1,100) == 0
                fprintf('\t Training on sample %d out of %d \r',s1,nSamplesTrain);
                end
                train = x{1}(:,:,s1);
                % train the decoder
                %decoder = train_LDA(cfg, y{1}, train');
                
                [Betas, fitInfo] = lassoglm(train, y{1}, 'binomial', 'Alpha', 1, 'Lambda',lambda, 'Standardize', true,'MaxIter',1e7);
                %test decoder on same samples it trained on (but diffferen trials,
                %obvs!)
                test = squeeze(x{2}(:,:,s1));
        
            
                % decoding
                %Betas(s1,:) = decode_LDA(cfg, decoder, test');
               
                B0 = fitInfo.Intercept;
                coef = [B0; Betas];
                yhat = glmval(coef,test,'logit');
                yhatBinom(testidx, s1) = (yhat>=0.5)'; %fix this
                
                       
                     
            end
              
         end
        
          Accuracy = squeeze(mean((yhatBinom)==repmat(Y,1,nSamples),1));
          save(fullfile(outputDir,'lassoLog.mat'),'Accuracy','-v7.3');

          %{
            figure;
            time = data.time;
            plot(time,Accuracy,'LineWidth',1); 
            hold on; 
            
            plot(xlim,[0.5 0.5],'k--','LineWidth',2)
            ylim([0,1])
            xlabel('Time (s)'); ylabel('Accuracy');
            xlim([time(1) time(end)]); title(strcat('Face v House ',num2str(lambda)))
          %}
        
         toc
    end
end
