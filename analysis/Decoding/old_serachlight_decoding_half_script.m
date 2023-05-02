

    %% Wrangle Data Into [Ntrials x NSources x NTime] Matrix

    %Record voxels inside brain
    inside = sourcezero.inside;

    %Remove outside voxels
    inside_idxs = find(inside); %inside voxel indices

    %zero trials
    zero_source_trials =[sourcezero.trial.mom];
    emptyCells = cellfun('isempty',zero_source_trials);
    zero_source_trials(emptyCells) = {zeros(size(sourcezero.time))};
    zero_source_trials = permute(reshape(cell2mat(zero_source_trials).',numel(zero_source_trials{1}),size(zero_source_trials,2),[]),[2 3 1]); %unnest nested timepoints
    zero_labels = zeros(1,size(zero_source_trials,1));

    %not zero trials
    not_zero_source_trials = [sourcenotzero.trial.mom];
    emptyCells = cellfun('isempty',not_zero_source_trials);
    not_zero_source_trials(emptyCells) = {zeros(size(sourcenotzero.time))};
    not_zero_source_trials = permute(reshape(cell2mat(not_zero_source_trials).',numel(not_zero_source_trials{1}),size(not_zero_source_trials,2),[]),[2 3 1]); %unnest nested timepoints
    notzero_labels = ones(1,size(not_zero_source_trials,1));

    %concat data from all conditions
    source_trials = [zero_source_trials; not_zero_source_trials];
    labels = [zero_labels notzero_labels]';

    %% Get Each Voxel's searchlight

    %Loop through each voxel, and get indices of neighbouring voxels
    dummy = reshape(1:11000, [20 25 22]);
    inside_vol = reshape(inside, [20 25 22]);
    searchlights = cell([20 25 22]);
    for i = 2:19
        for j = 2:24
            for k =2:21
                tmp = dummy(i+[-1:1], j+[-1:1],k+[-1:1]); % gets 26 neighboruing voxels (27 - original voxel)
                searchlights{i,j,k} = tmp(:);
            end
        end
    end

    %% Decode!
    acc_vol = nan([20 25 22]);%to store accuracy
    %Get data from within each searchlight
    for slx = 1:size(searchlights,1)
        disp(slx)
        for sly = 1:size(searchlights,2)
            for slz = 1:size(searchlights,3)

                if ~inside_vol(slx,sly,slz)
                    %if outside brain we can skip
                    continue
                end
                
                X = source_trials(:,searchlights{slx,sly,slz},:); %get data
                Y = labels;

                if isempty(X)
                    %some searchlights are empty if the voxel is on the border of the volume
                    continue
                end

                %loop over time and decode
                cfgS = [];
                cfgS.classifier = 'lda';
                cfgS.metric = 'acc';
                cfgS.preprocess ={'undersample'};
                cfgS.repeat = 1;
                cfgS.feedback = false;
                [results_dot,~] = mv_classify(cfgS,X,Y); %decode searchlight

                %add back to accuracy volume (averaging over time for now)
                acc_vol(slx,sly,slz) = mean(results_dot);

                
            end
        end
    end