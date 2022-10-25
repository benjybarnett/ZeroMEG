clear all;
subj = 'sub05';
data_dir = 'D:\bbarnett\Documents\Zero\data\Raw';
files = dir(fullfile(data_dir,subj,'meg','trial_data','*.mat'));

%% MAIN TASK

n_trials = 864;
n_blocks = 9;
results = {};

for f = 1:size(files,1)
    if contains(files(f).name,'results_block')
        %create a cell array. Each cell is a struct from a block with
        %results in
        results{f} = load(fullfile(files(f).folder,files(f).name));
        
    elseif contains(files(f).name,'trialMatrix')
        %load the trial matrix
        load(fullfile(files(f).folder,files(f).name));
    end
end

results = results(~cellfun('isempty',results)); %remove empty cells

data = {}; %this will store our data by the end

%% Columns 1:3
%Block, TrialNumber, Task
data{1} = trialMatrix(:,1); %Block number
data{:,2} = repmat(1:96,[1,n_blocks])'; %Trial number within block
data{:,3} = trialMatrix(:,2); %Task (1 for number, 2 for detection)

%% Detection Columns (Cols 4:12)
%miniblock, stim present,  visibility,response, RT, correct, confidence,
%confidence RT, fixation duration

miniblocks = trialMatrix(:,3); %miniblock (1 for houses, 2 for face)
miniblocks(data{:,3} == 1) = nan;%remove info from num trials
data{:,4} = miniblocks;
clear miniblocks

stimPresent = trialMatrix(:,4); 
stimPresent(data{:,3} == 1) = nan;
data{:,5} = stimPresent; %stimPresent (1 for present, 2 for absent);
clear stimPresent

faceVisibility = vertcat(repmat(results{1,1}.params.faceVisibility,[96,1]),...
                        repmat(results{1,2}.params.faceVisibility,[96,1]),...
                        repmat(results{1,3}.params.faceVisibility,[96,1]),...
                        repmat(results{1,4}.params.faceVisibility,[96,1]),...
                        repmat(results{1,5}.params.faceVisibility,[96,1]),...
                        repmat(results{1,6}.params.faceVisibility,[96,1]),...
                        repmat(results{1,7}.params.faceVisibility,[96,1]),...
                        repmat(results{1,8}.params.faceVisibility,[96,1]),...
                        repmat(results{1,9}.params.faceVisibility,[96,1]));
visibility = nan(length(data{:,3}),1);
visibility(data{:,4} == 2) = faceVisibility(data{:,4} == 2); %add only on face trials
          

houseVisibility = vertcat(repmat(results{1,1}.params.houseVisibility,[96,1]),...
                        repmat(results{1,2}.params.houseVisibility,[96,1]),...
                        repmat(results{1,3}.params.houseVisibility,[96,1]),...
                        repmat(results{1,4}.params.houseVisibility,[96,1]),...
                        repmat(results{1,5}.params.houseVisibility,[96,1]),...
                        repmat(results{1,6}.params.houseVisibility,[96,1]),...
                        repmat(results{1,7}.params.houseVisibility,[96,1]),...
                        repmat(results{1,8}.params.houseVisibility,[96,1]),...
                        repmat(results{1,9}.params.houseVisibility,[96,1]));
visibility(data{:,4} == 1) = houseVisibility(data{:,4} == 1); %add only on house trials

data{:,6} = visibility; %visibility

clear visibility faceVisibility houseVisibility

%response
faceResponses = combine_across_blocks('faces.detection',results);
responses = nan(length(data{:,3}),1);
responses(data{:,4} == 2) = faceResponses; %add only on face trials

houseResponses = combine_across_blocks('houses.detection',results);
responses(data{:,4} == 1) = houseResponses; %add only on house trials
data{:,7} = responses; %detection responses

clear responses houseResponses faceResponses

%RT
faceRT= combine_across_blocks('faces.detection_RT',results);
detRT = nan(length(data{:,3}),1);
detRT(data{:,4} == 2) = faceRT; %add only on face trials

houseRT = combine_across_blocks('houses.detection_RT',results);
detRT(data{:,4} == 1) = houseRT; %add only on house trials
data{:,8} = detRT; %detection reaction time

clear detRT houseRT faceRT

%Correct
faceCorrect= combine_across_blocks('faces.correct',results);
detCorrect = nan(length(data{:,3}),1);
detCorrect(data{:,4} == 2) = faceCorrect; %add only on face trials

houseCorrect= combine_across_blocks('houses.correct',results);
detCorrect(data{:,4} == 1) = houseCorrect; %add only on house trials
data{:,9} = detCorrect; %detection correct (1 for correct, 0 for incorrect)

clear detCorrect houseCorrect faceCorrect

%Confidence
faceConf= combine_across_blocks('faces.confidence',results);
detConf = nan(length(data{:,3}),1);
detConf(data{:,4} == 2) = faceConf; %add only on face trials

houseConf= combine_across_blocks('houses.confidence',results);
detConf(data{:,4} == 1) = houseConf; %add only on house trials
data{:,10} = detConf; 

clear houseConf faceConf detConf

%Confidence RT %Skip for now as not got enough trials in blocks
detConfRT = nan(length(data{:,3}),1);
data{:,11} = detConfRT;

faceConfRT= combine_across_blocks('faces.confidence_RT',results);
detConfRT = nan(length(data{:,3}),1);
detConfRT(data{:,4} == 2) = faceConfRT; %add only on face trials

houseConfRT= combine_across_blocks('houses.confidence_RT',results);
detConfRT(data{:,4} == 1) = houseConfRT;%add only on house trials
data{:,11} = detConfRT; %detection reaction time


clear detConfRT houseConfRT faceConfRT

%fixation duration

fixation = vertcat(1,results{1,1}.params.ITI,...
                        1,results{1,2}.params.ITI,...
                        1,results{1,3}.params.ITI,...
                        1,results{1,4}.params.ITI,...
                        1,results{1,5}.params.ITI,...
                        1,results{1,6}.params.ITI,...
                        1,results{1,7}.params.ITI,...
                        1,results{1,8}.params.ITI,...
                        1,results{1,9}.params.ITI); %add 1s in for the initial fixatino at beginning of each block
fixation(97:97:end) = []; %remove last fixation of each block because no stim comes after them

detFix = nan(length(data{:,3}),1);
detFix(data{:,3} == 2) = fixation(data{:,3} == 2); %add only on det trials

data{:,12} = detFix; %visibility

clear detFix

%% Numerical Columns (Cols 13:22)

% Stim Type, Sample Number, Test Number, NumMatch, Num Response, NumRT,
% numCorrect,sampleImage, testImage, numFixation

%stim type 
stimType = trialMatrix(:,3);
stimType(data{:,3} == 2) = nan;%remove info from det trials
data{:,13} = stimType; %1 for standard, %2 for control

clear stimType

%sample number
sampleNumber = trialMatrix(:,4);
sampleNumber(data{:,3} == 2) = nan;%remove info from det trials
data{:,14} = sampleNumber; 

clear sampleNumber

%test number
testNumber = trialMatrix(:,5);
testNumber(data{:,3} == 2) = nan;%remove info from det trials
data{:,15} = testNumber; 
clear testNumber

%do the sample and test match number
samples = data{:,14};
tests = data{:,15};
numMatch = [];
for i = 1:length(tests)
    if samples(i) == tests(i)
        numMatch(i,1) = 1;
    else
        numMatch(i,1) = 0;
    end
end
numMatch(data{:,3} == 2) = nan;%remove info from det trials
data{:,16} = numMatch;
clear numMatch 

%Number Response
numResp= combine_across_blocks('num_resp',results);
resps = nan(length(data{:,3}),1);
resps(data{:,3} == 1) = numResp; %add only on num trials
data{:,17} = resps; 
clear numResp resps

%Number RT
numRT= combine_across_blocks('num_RT',results);
RTs = nan(length(data{:,3}),1);
RTs(data{:,3} == 1) = numRT; %add only on num trials
data{:,18} = RTs; 
clear numRT RTs


%Number Correct
numCorr= combine_across_blocks('num_correct',results);
corrects = nan(length(data{:,3}),1);
corrects(data{:,3} == 1) = numCorr; %add only on num trials
data{:,19} = corrects; 
clear numCorr corrects



%num fixation
numFix = nan(length(data{:,3}),1);
numFix(data{:,3} == 1) = fixation(data{:,3} == 1); %add only on num trials
data{:,20} = numFix;

clear numFix fixation
%% Save as CSV
outputFile = fullfile(data_dir,subj,'meg','trial_data','data.mat');

data = cell2mat(data);
save(outputFile,'data');

outputFile = fullfile(data_dir,subj,'meg','trial_data','data.csv');

data = array2table(data);
data.Properties.VariableNames= {'Block'	'TrialNumber'	'Task'	'MiniBlock'	'StimPresent'	'Visibility'...
    'DetResponse'	'DetRT'	'DetCorrect'	'Confidence'	'ConfidenceRT'...
    'DetFixationDur'	'StimType'	'SampleNum'	'TestNum'	'NumMatch'	'NumResponse'	'NumRT'...
    'NumCorrect'		'NumFixationDur'};
writetable(data,outputFile)

%% save dot file names as separate csv as they are strings

%sample image
dotImages = combine_across_blocks('dot_images',results);
sample_images = dotImages(:,1);
test_images = dotImages(:,2);

samples = {};
samples(data{:,3} == 1,1) = sample_images;
%data{:,20} = samples;

%test image
tests = {};
tests(data{:,3} == 1,1) = test_images;
%data{:,21} = tests;

outputFile = fullfile(data_dir,subj,'meg','trial_data','dot_files.mat');

dot_files{1} = samples;
dot_files{2} = tests;

save(outputFile, 'dot_files')
%{
%% LOCALIZER TASK
n_trials = 168;
n_blocks = 2;
loc_results = {};

idx = 1;
for f = 1:size(files,1)
    if contains(files(f).name,'results_localizer_block')
        %create a cell array. Each cell is a struct from a block with
        %results in
        loc_results{idx} = load(fullfile(files(f).folder,files(f).name));  
        idx=idx+1;
    end
end

loc_data = []; %this will store our data by the end
for block = 1:size(loc_results,2)
    loc_data =[loc_data loc_results{block}.trials];
end
loc_data = loc_data(:); %flatten

outputFile = fullfile(data_dir,subj,'meg','trial_data','loc_data.mat');
save(outputFile,"loc_data")
%}