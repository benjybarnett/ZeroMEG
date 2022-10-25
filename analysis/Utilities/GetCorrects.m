function [zero_correct, one_correct, two_correct, three_correct] = GetCorrects(data)

    %Calculates the correct rate for match trials
    
    zero_correct = size(data(data(:,19) == 1 & data(:,17) == 1 & data(:,14) == 0,:),1)/...
                    size(data(data(:,14) == 0 & data(:,15) == 0),1) * 100;
                
    one_correct = size(data(data(:,19) == 1 & data(:,17) == 1 & data(:,14) == 1,:),1)/...
        size(data(data(:,14) == 1 & data(:,15) == 1),1) * 100;

    two_correct = size(data(data(:,19) == 1 & data(:,17) == 1 & data(:,14) == 2,:),1)/...
        size(data(data(:,14) == 2 & data(:,15) == 2),1) * 100;
       
    three_correct = size(data(data(:,19) == 1 & data(:,17) == 1 & data(:,14) == 3,:),1)/...
        size(data(data(:,14) == 3 & data(:,15) == 3),1) * 100;
end