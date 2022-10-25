function num_trials = diagDecode(cfg0,subject)

% output directory
outputDir = fullfile(cfg0.root,cfg0.outputDir,subject);
if ~exist(outputDir,'dir'); mkdir(outputDir); end

%load data
disp('loading..')
disp(subject)
if strcmp(cfg0.task,'detection')    
    data = load(fullfile(cfg0.root,'CleanData',subject,'det_data.mat'));
    correctIdx = 9;
    labels = data.det_data.det_labels;
elseif strcmp(cfg0.task,'number')
    data = load(fullfile(cfg0.root,'CleanData',subject,'num_data.mat'));
    correctIdx = 19;
elseif strcmp(cfg0.task,'localizer')
    %data = load(fullfile(cfg0.root,'CleanData',subject,'loc_data.mat'));
    data = load(fullfile(cfg0.root,'CleanData',subject,'data.mat'));
else
    error('Task Not Recognised')
end
data = struct2cell(data); data = data{1};
disp('loaded data')

% select ony MEG channels  and appropriate trials
if ~cfg0.correct
    trls = eval(strcat('(',cfg0.conIdx{1}," | ",cfg0.conIdx{2}, ')' ));
else
    trls = eval(strcat('(',cfg0.conIdx{1}," | ",cfg0.conIdx{2},") & data.trialinfo(:,",num2str(correctIdx),")== 1"));
    
end

cfgS             = [];
cfgS.channel     = 'MEG';
cfgS.trials      = trls;
cfgS.keeptrials  = 'yes';
data             = ft_timelockanalysis(cfgS,data);

% check if this analysis already exists
%if ~exist(fullfile(outputDir,[cfg0.outputName '.mat']),'file')
    
    
    % create labels and balance classes
    labels = eval(cfg0.conIdx{1});%labels is a Ntrials length vector with 1 for one class and 0 for the other
    
    %balance the number of trials of each condition
    idx = balance_trials(double(labels)+1,'downsample'); %idx is a Nclass x 1 cell, each cell with [Ntrials x 1] containing indices for trials of particular classs
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
       
        
        
        Xhat(:,testidx) = decodingDiag(cfg0,x,y); %decode here
        
    end
  
    
    %1. Xhat > 0 finds all values in Xhat greater than 0, returning 1 in that element's location if element > 0 and 0 if element < 0.
    %2. the == etc. finds all values in the above boolean matrix that have the same value as Y, which are the correct trial labels
    %3. the mean function then takes an average of these values across all trials for each sample point
    Accuracy = squeeze(mean((Xhat>0)==permute(repmat(Y,1,nSamples),[2,1]),2));
  
disp(fullfile(outputDir,cfg0.outputName))
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