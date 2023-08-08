function [data,labels] = UndersampleBinarise(cfg0,data,labels)
    % Function to Binarise classes whilst undersampling. 
    % Coded so that class 1 is target class and classes 2+ are non-target.
    % Results in non-target classes all having same number of samples
    % when binarised into target vs non-target.
    nclasses = max(labels); 
    
    % Sample count for each class
    N = arrayfun( @(c) sum(labels==c) , 1:nclasses);
    
    
    % undersample the majority class(es)
    rm_samples = abs(N - min(N));
    for cc=1:nclasses
        if rm_samples(cc)>0
            ix_this_class = find(labels == cc);
            ix_rm = randperm( numel(ix_this_class), rm_samples(cc));
    
            % Remove samples from data and labels
            
            data(ix_this_class(ix_rm),:,:)= [];
            labels(ix_this_class(ix_rm))= [];
        end
    end
    
    N = arrayfun( @(c) sum(labels==c) , 1:nclasses);

    % Now cut down the non-zero classes to 1/5th of number of zero trials
    nClassNzero = round(N(1)/cfg0.numNTClass); 
    rm_samples = N - nClassNzero;
    for cc = 2:nclasses
        ix_this_class = find(labels == cc);
        ix_rm = randperm( numel(ix_this_class), rm_samples(cc));
        data(ix_this_class(ix_rm),:,:)= [];
        labels(ix_this_class(ix_rm))= [];
        disp(arrayfun( @(c) sum(labels==c) , 1:nclasses));
        
    end

end