function num_trials = diagDecodeOneVsAllLOC(cfg0,subject)
%Decode individual stim classes versus all other stim classes. Do this
%diagonally across time.


% output directory
outputDir = fullfile(cfg0.root,cfg0.outputDir,subject);
if ~exist(outputDir,'dir'); mkdir(outputDir); end

%load data
disp('loading..')
disp(subject)
if strcmp(cfg0.task,'detection')    
    data = load(fullfile(cfg0.root,'CleanData',subject,'det_data.mat'));
    correctIdx = 9;
elseif strcmp(cfg0.task,'number')
    data = load(fullfile(cfg0.root,'CleanData',subject,'num_data.mat'));
    correctIdx = 19;
elseif strcmp(cfg0.task,'localizer')
    data = load(fullfile(cfg0.root,'CleanData',subject,'data.mat'));
    stimIdx = 3; %index of trial info matrix that has stim classes 
else
    error('Task Not Recognised')
end
data = struct2cell(data); data = data{1};
disp('loaded data')


cfgS             = [];
cfgS.channel     = 'MEG';
%cfgS.trials      = trls;
cfgS.keeptrials  = 'yes';
data             = ft_timelockanalysis(cfgS,data);

for row = 1:length(data.trialinfo)
    if data.trialinfo(row,2) == 1
        data.trialinfo(row,3) = data.trialinfo(row,3) + 4;
    end
end


%trial average
%{
labels = unique(data.trialinfo(:,1));
dataav =[];
labelsav = [];
for i = 1:length(labels)
    label = labels(i);
    trials = data.trialinfo(:,stimIdx) == label;
    trial_data = data.trial(trials,:,:);
    ntrl = size(trial_data,1);
    if mod(ntrl,4) %if nto divisible by 4
        rem = mod(ntrl,4);
        last_trl = trial_data(end-(rem-1):end,:,:);
        data_remove_last = trial_data(1:ntrl-rem,:,:);
        avg_data = squeeze(mean(reshape(data_remove_last,[4,size(data_remove_last,1)/4,size(data_remove_last,2),size(data_remove_last,3)])));
        
        avg_data = [avg_data;last_trl];
    else
        avg_data = squeeze(mean(reshape(trial_data,[4,size(trial_data,1)/4,size(trial_data,2),size(trial_data,3)])));
    end
    lbls = repmat(label,[size(avg_data,1)],1);
    labelsav = [labelsav; lbls];
    
    dataav = [dataav; avg_data];

end
data.trial = dataav;
data.trialinfo = labelsav;
%}
% check if this analysis already exists
%if ~exist(fullfile(outputDir,[cfg0.outputName '.mat']),'file')
    
    
    %Binarise classes
    labels = data.trialinfo(:,stimIdx)==cfg0.classifier;%labels is a Ntrials length vector with 1 for one class and 0 for the others
    
    


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
    Xhat = zeros(nSamples,nTrials);
    for f = 1:cfg0.nFold
        trainidx = setdiff(1:nTrials,folds{f}); %return indices of trials not in fold - used for training
        testidx = folds{f}; %return indices of trials in fold - used for testing
        x{1} = X(trainidx,:,:); x{2} = X(testidx,:,:); %split training and testing data into two cells in one cell array
        y{1} = Y(trainidx); y{2} = Y(testidx); %split training and testing labels into two cells in one cell array
        
        fprintf('Decoding fold %d out of %d \n',f,cfg0.nFold)
       
        if strcmp(cfg0.decoder, 'lda')
            Xhat(:,testidx) = decodingDiag(cfg0,x,y); %decode here
        elseif strcmp(cfg0.decoder, 'lassolog')

            for s1 = 1:nSamples
                
                %smooth
                % define the training set
                
                if s1 <= cfg0.nMeanS/2 || s1 >= nSamples - (cfg0.nMeanS/2)
                    yhatBinom(:,s1) = NaN;

                else
                    train = squeeze(mean(x{1}(:,:,round(s1 - cfg0.nMeanS/2):round(s1 + cfg0.nMeanS/2)),3));
                    if sum(isnan(train(1,:))) > 1
                        yhatBinom(:,s1) = NaN;
                    else
                
                        if mod(s1,100) == 0
                            fprintf('\t Training on sample %d out of %d \r',s1,nSamples);
                        end
                        %train = x{1}(:,:,s1);
                        % train the decoder
                        
                        
                        [Betas, fitInfo] = lassoglm(train, y{1}, 'binomial', 'Alpha', 1, 'Lambda',cfg0.lambda, 'Standardize', true);
                        %test decoder on same samples it trained on (but diffferen trials,
                        %obvs!)
                       %test = squeeze(x{2}(:,:,s1));
                        test = squeeze(mean(x{2}(:,:,round(s1 - cfg0.nMeanS/2):round(s1 + cfg0.nMeanS/2)),3));

                    
                        % decoding
                        %Betas(s1,:) = decode_LDA(cfg, decoder, test');
                       
                        B0 = fitInfo.Intercept;
                        coef = [B0; Betas];
                        yhat = glmval(coef,test,'logit');
                        %disp(size(yhat))
                        %disp(testidx)
                        yhatBinom(testidx, s1) = (yhat>=0.5)'; 
                           
                         
                    end
                end
            end
        end

        
    end
  
    if strcmp(cfg0.decoder,'lda')
        %1. Xhat > 0 finds all values in Xhat greater than 0, returning 1 in that element's location if element > 0 and 0 if element < 0.
        %2. the == etc. finds all values in the above boolean matrix that have the same value as Y, which are the correct trial labels
        %3. the mean function then takes an average of these values across all trials for each sample point
        Accuracy = squeeze(mean((Xhat>0)==permute(repmat(Y,1,nSamples),[2,1]),2));
    elseif strcmp(cfg0.decoder, 'lassolog')
        Accuracy = squeeze(mean((yhatBinom)==repmat(Y,1,nSamples),1));
        Accuracy = Accuracy';
    end

    save(fullfile(outputDir,cfg0.outputName),'Accuracy','-v7.3');
    disp('saving....')

%{
else
    warning('Analysis already exists, loading for plotting');
    load(fullfile(outputDir,cfg0.outputName),'Accuracy');
end

%}

% plot
if cfg0.plot
    figure;
    time = data.time;
    plot(time,Accuracy,'LineWidth',1); 
    hold on; 
    
    plot(xlim,[0.5 0.5],'k--','LineWidth',2)
    ylim([0,1])
    xlabel('Time (s)'); ylabel('Accuracy');
    xlim([time(1) time(end)]); title(cfg0.title)

end