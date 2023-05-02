subjects = {
    'sub001'
    'sub002' 
    'sub003'
    'sub004'
    'sub005'
    'sub006'
    %'sub007' %Removed for sleeping and 48% accuracy on arabic task
    

    };

fro_acc = [];
par_acc = [];

fro_conf = [];
par_conf = [];



for subj = 1:length(subjects)
    subject = subjects{subj};
    load(fullfile('D:\bbarnett\Documents\Zero\data\Analysis\MEG\Source\Decoding\arabic\parietal\',subject,'results.mat'))
    acc = results{1};
    par_acc = [par_acc acc];

    load(fullfile('D:\bbarnett\Documents\Zero\data\Analysis\MEG\Source\Decoding\arabic\frontal\',subject,'results.mat'))
    acc = results{1};
    fro_acc = [fro_acc acc];

end
%group accuracies over time
mean_par = mean(par_acc,2);
mean_fro = mean(fro_acc,2);

figure;plot(mean_par); hold on;
yline(1/6,'--r');xline(0,'--');title('Parietal Source Decoding')

figure;plot(mean_fro); hold on;
yline(1/6,'--r');xline(0,'--');title('Frontal Source Decoding')



