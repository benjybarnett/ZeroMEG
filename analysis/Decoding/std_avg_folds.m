function zsubj_dvals = std_avg_folds(subj_dvals)
% Calculates Z score of classifier distance values for each fold of each
% classifier across different test classes and then averages across folds
% within each test class.
% Input: subj_dvals = [1 x num_subjects] cell array. Each cell contains
%                     a [N_decoder x N_test_class] cell array. Each of these
%                     contains a [1 x num folds] cell array.
% Output: zsubj_dvals = Cell array of same dimensions as input, with values
%                       Z-scored across test classes for each fold of each 
%                       classifier

%% This now unused and broken
    zsubj_dvals = cell(size(subj_dvals));
    for subject = 1:length(subj_dvals)
        dvals = subj_dvals{subject};
        for clf = 1:size(dvals,1)
            clf_dval = [dvals{clf,:}];
            mu = mean(clf_dval);
            sd = std(clf_dval);  
            for test_class = 1:size(dvals,2)
                zsubj_dvals{1,subject}{clf,test_class} = ( subj_dvals{1,subject}{clf,test_class} - mu ) ./ sd;
            end
        end
    end

end