function idx = balance_trials(y,samplemethod,ntrials,y_binary)
% function idx = balance_trials(y,samplemethod,ntrials)
% balances the number of trials per class for classification
%
%  INPUT:   y             = trials x 1 labels 
%           balancemethod = 'downsample' or 'upsample' or 'downsample vs
%           all'
%           ntrials (optional) = specify the number of trials per class
%           y_binary = trials x 1 labels in binary format (for use if
%           y argument is multiclass and using 'downsample vs all' method)
% OUTPUT:   idx           = cell structure with balanced indices per class
%
% Developed by Nadine Dijkstra 2016 and extended by Benjy Barnett 2022
% 


% for repeatability
rng(1,'twister');

if strcmp(samplemethod,'upsample') % upsample other classes
    [~,b] = max(histc(y,unique(y))); % class with most trials
    nclasses = numel(unique(y));
    if nargin < 3
    ntrials = size(find(y == b),1);
    end
    idx = cell(nclasses,1);
    
    for c = 1:nclasses
        indices = find(y == c);
        while numel(indices)<ntrials
            ind = indices;
            indices = [indices;ind(randi(numel(ind)))];
        end
        idx{c} = indices;
        clear indices
    end
    
elseif strcmp(samplemethod,'downsample') % downsample other classes
    [~,b] = min(histc(y,unique(y))); % class with least trials
    nclasses = numel(unique(y));
    if nargin < 3
        ntrials = size(find(y == b),1);
    end
    idx = cell(nclasses,1);
    
    for c = 1:nclasses
        indices = find(y == c);
        while numel(indices)>ntrials
            indices(randi(numel(indices))) = []; % randomly delete one
        end
        idx{c} = indices;
        clear indices
    end

elseif strcmp(samplemethod,'downsample vs all') 
    %for use in one vs. all procedure where you want to balance positive
    %and negative examples, but also balance the examples within the
    %negative trials 
    [~,b] = min(histc(y_binary,unique(y_binary))); % class with least trials from binary labels
    nclasses = numel(unique(y_binary)); %get total classes (accoutning for different negative classes)
    targetclass = y(logical(y_binary-1));
    targetclass = targetclass(1);
    allclasses = unique(y);
    ntrials = size(find(y_binary == b),1);
    idx = cell(nclasses,1);

    for c = 1:nclasses
        if c == b %target class
            idx{c} = find(y_binary == c);
        else
            count = 1;
            neg_trials = [];
            
            while numel(neg_trials) < ntrials
                 disp(numel(neg_trials))
                for i = 1:length(allclasses)
                    
                    class = allclasses(i); %get current class
                    ind = find(y==class); %get indices of this class
                    ind = ind(randperm(length(ind))); %shuffle indices so we dont select same one each time
                    notrepeated=true;
                    if class ~= targetclass %if non-target class
                        while notrepeated %make sure dont select same trial twice
                            %disp(count)
                            trial = (ind(count)); %get index of trial of this class
                            if ismember(trial,neg_trials) %do again if we've selected same trial twice
                                notrepeated = false;
                               
                            else
                                neg_trials = [neg_trials trial]; %add trial to list of trials to use for non-target class
                                notrepeated = true;
                                
                            end
                        end

                    end
                    
                end
                
                count = count+1;
                
                  
            end

            %randomly cut off excess trials. Can't balance negative examples completely.
            nremove = numel(neg_trials) - ntrials;
            removeidx = randi(ntrials);
            removeidxs = removeidx:removeidx+nremove-1;
            neg_trials(removeidxs)=[];
            idx{c} = neg_trials';
                
        end

            
       
    end

end
end

