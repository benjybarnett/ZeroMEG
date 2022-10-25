function [zero_incorrect, one_incorrect, two_incorrect, three_incorrect] = GetIncorrects(data)

    %Calculates the incorrect rate across pairwise combinations of all
    %numerosities for a subject. These values amount to the non-peak points
    %in the behavioural tuning curves.
    
    %total combination of numbers (matched so equal for all pairs)
    total_comb = size(data((data(:,14) ==1)&(data(:,15) == 2),:),1) ;
    
    %when sample is 0, and they see another number and report same
    zero_incorrect = [(size(data((data(:,14) == 0) &(data(:,15) == 1)& (data(:,17) ==1),:),1)/total_comb)*100,...
                    (size(data((data(:,14) == 0) &(data(:,15) == 2)&  (data(:,17) == 1),:),1)/total_comb)*100,...
                    (size(data((data(:,14) == 0) &(data(:,15) == 3)&  (data(:,17) == 1),:),1)/total_comb)*100];

    one_incorrect = [(size(data((data(:,14) == 1) &(data(:,15) == 0)& (data(:,17) ==1),:),1)/total_comb)*100,...
                    (size(data((data(:,14) == 1) &(data(:,15) == 2)&  (data(:,17) == 1),:),1)/total_comb)*100,...
                    (size(data((data(:,14) == 1) &(data(:,15) == 3)&  (data(:,17) == 1),:),1)/total_comb)*100];

    two_incorrect = [(size(data((data(:,14) == 2) &(data(:,15) == 1)& (data(:,17) ==1),:),1)/total_comb)*100,...
                    (size(data((data(:,14) == 2) &(data(:,15) == 0)&  (data(:,17) == 1),:),1)/total_comb)*100,...
                    (size(data((data(:,14) == 2) &(data(:,15) == 3)&  (data(:,17) == 1),:),1)/total_comb)*100];

    
    three_incorrect = [(size(data((data(:,14) ==3) &(data(:,15) == 1)& (data(:,17) ==1),:),1)/total_comb)*100,...
                    (size(data((data(:,14) == 3) &(data(:,15) == 2)&  (data(:,17) == 1),:),1)/total_comb)*100,...
                    (size(data((data(:,14) == 3) &(data(:,15) == 0)&  (data(:,17) == 1),:),1)/total_comb)*100];

                
end