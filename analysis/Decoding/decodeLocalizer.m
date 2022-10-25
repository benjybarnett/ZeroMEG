function decodeLocalizer(cfg0,subject)
%% Decode localizer data for each subject
%Create a new binary classifier for each stimulus type and test on 
%each of the different stimulus types separately. Trains on one time
%point and tests on all time points.

%% Parameters
nSensors = 273;
nStims = 7;

%% Load localizer data
data_dir = fullfile(cfg0.root,'CleanData',subject,'loc_data.mat');
data = load(data_dir);
data = data.loc_data;

% select ony MEG channels  and appropriate trials
cfgS             = [];
cfgS.channel     = 'MEG';
cfgS.keeptrials  = 'yes';
data             = ft_timelockanalysis(cfgS,data);

%% Train Classifiers
W = nan(nSensors, nStims); 

for classifier = 1:nStims

    fprintf('Training classifier %d out of %d \n',classifier,nStims)

    %Binarise classes
    labels = data.trialinfo(:,1)==classifier;%labels is a Ntrials length vector with 1 for one class and 0 for the others
    
    %balance the number of trials of each condition
    %EDIT THIS TO BALANCE ALL NEGATIVE CLASSES?
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
    nTrials = size(X,1); nSamples = size(X,3); trainSample = 121;
    Xhat = zeros(nSamples,nTrials);
    trueTestIdx = []; %indexes for trials with true stimulus type with respect to classifier. E.g. if classifier for houses, get indexes of when tested on only house trials
        
    for f = 1:cfg0.nFold
        trainidx = setdiff(1:nTrials,folds{f}); %return indices of trials not in fold - used for training
        testidx = folds{f}; %return indices of trials in fold - used for testing
        x{1} = X(trainidx, :, trainSample); x{2} = X(testidx,:,:); %split training and testing data into two cells in one cell array
        y{1} = Y(trainidx); y{2} = Y(testidx); %split training and testing labels into two cells in one cell array
        
        fprintf('Decoding fold %d out of %d \n',f,cfg0.nFold)
       
        trueTestIdx =[trueTestIdx testidx(y{2}==1)];  %true examples
        
        Xhat(:,testidx) = decodingFromSingleSample(cfg0,x,y); %decode here
        
    end
    
    trueXhat = Xhat(:,trueTestIdx); %select Xhat for trials matching that of classifier

    %1. Xhat > 0 finds all values in Xhat greater than 0, returning 1 in that element's location if element > 0 and 0 if element < 0.
    %2. the == etc. finds all values in the above boolean matrix that have the same value as Y, which are the correct trial labels
    %3. the mean function then takes an average of these values across all trials for each sample point
    Accuracy = squeeze(mean((trueXhat>0)==permute(ones(nTrials/2,nSamples),[2,1]),2));
  
    %save accuracy
    outputDir = fullfile(cfg0.root,cfg0.outputDir,subject);
    if ~exist(outputDir,'dir'); mkdir(outputDir); end
    outputName = strcat('classifier_',num2str(classifier));
    save(fullfile(outputDir,outputName),'Accuracy','-v7.3');


    hold on;
    plot(data.time(1:5:end),Accuracy(1:5:end),'LineWidth',0.2);

 
end

 Legend=cell(7,1);
 Legend{1}='Houses' ;
 Legend{2}='Faces';
 Legend{3}='Nothing' ;
 Legend{4}='Zero';
 Legend{5}='One' ;
 Legend{6}='Two';
 Legend{7}='Three';
 legend(Legend);
 yline(0.5)
 hold off


end