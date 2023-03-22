clear all;
subj = 'sub009';
data_dir = 'D:\bbarnett\Documents\Zero\data\Raw';
files = dir(fullfile(data_dir,subj,'meg','trial_data','*.mat'));

%% MAIN TASK

n_trials = 801;
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
data{:,2} = repmat(1:89,[1,n_blocks])'; %Trial number within block
data{:,3} = trialMatrix(:,2); %Task (1 for dots, 2 for arabic)

%% Arabic Columns (Cols 4:27)
%numbers, colours,  response, RT, correct

%numbers
numbers = trialMatrix(:,3:12); %number sequence presented
numbers(data{:,3} == 1,:) = nan;%remove info from num trials
data{:,4} = numbers;
clear numbers

%colours
colours = trialMatrix(:,13:end); 
colours(data{:,3} == 1,:) = nan;
data{:,5} = colours; %colour sequence
clear colours

%response
arabicResponses = combine_across_blocks('arabic_response',results);
responses = nan(length(data{:,3}),1);
responses(data{:,3} == 2) = arabicResponses;
data{:,6} = responses;
clear arabicResponses

%RT
arabicRT = combine_across_blocks('arabic_RT',results);
RT = nan(length(data{:,3}),1);
RT(data{:,3} == 2) = arabicRT;
data{:,7} = RT;

clear RT

%Correct
correct= combine_across_blocks('arabic_correct',results);
Correct = nan(length(data{:,3}),1);
Correct(data{:,3} == 2) = correct; 

data{:,8} = Correct; 

clear correct


%% Numerical Columns (Cols 27:33)

% Stim Type, Sample Number, Test Number, NumMatch, Num Response, NumRT,
% numCorrect

%stim type 
stimType = trialMatrix(:,3);
stimType(data{:,3} == 2) = nan;%remove info from arabic trials
data{:,9} = stimType; %1 for standard, %2 for control

clear stimType

%sample number
sampleNumber = trialMatrix(:,4);
sampleNumber(data{:,3} == 2) = nan;%remove info from arabic trials
data{:,10} = sampleNumber; 

clear sampleNumber

%test number
testNumber = trialMatrix(:,5);
testNumber(data{:,3} == 2) = nan;%remove info from det trials
data{:,11} = testNumber; 
clear testNumber

%do the sample and test match number
samples = data{:,10};
tests = data{:,11};
numMatch = [];
for i = 1:length(tests)
    if samples(i) == tests(i)
        numMatch(i,1) = 1;
    else
        numMatch(i,1) = 0;
    end
end
numMatch(data{:,3} == 2) = nan;%remove info from arabic trials
data{:,12} = numMatch;
clear numMatch 

%Number Response
numResp= combine_across_blocks('num_resp',results);
resps = nan(length(data{:,3}),1);
resps(data{:,3} == 1) = numResp; %add only on num trials
data{:,13} = resps; 
clear numResp resps

%Number RT
numRT= combine_across_blocks('num_RT',results);
RTs = nan(length(data{:,3}),1);
RTs(data{:,3} == 1) = numRT; %add only on num trials
data{:,14} = RTs; 
clear numRT RTs


%Number Correct
numCorr= combine_across_blocks('num_correct',results);
corrects = nan(length(data{:,3}),1);
corrects(data{:,3} == 1) = numCorr; %add only on num trials
data{:,15} = corrects; 
clear numCorr corrects


%% Save as CSV
outputFile = fullfile(data_dir,subj,'meg','trial_data','data.mat');

data= cell2mat(data);
save(outputFile,'data');

outputFile = fullfile(data_dir,subj,'meg','trial_data','data.csv');

data = array2table(data);
data.Properties.VariableNames= {'Block'	'TrialNumber'	'Task'	'Number1'	'Number2'	'Number3'...
    'Number4'	'Number5'	'Number6'	'Number7'	'Number8' 'Number9' 'Number10' 'Colour1'	'Colour2'	'Colour3'...
    'Colour4'	'Colour5'	'Colour6'	'Colour7'	'Colour8' 'Colour9' 'Colour10' 'ArabicResp','ArabicRT' 'ArabicCorrect'...
    'StimType'	'SampleNum'	'TestNum'	'NumMatch'	'NumResponse'	'NumRT'...
    'NumCorrect'};
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
