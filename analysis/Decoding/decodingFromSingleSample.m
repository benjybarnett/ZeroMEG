function Xhat = decodingFromSingleSample(cfg,X,Y)
% function decodingDiag(cfg,X,Y)
%
% Trains a classifier on the data in X{1} and classifies the data in X{2}.
% Testing on all samples but training on only one.
% 
%     INPUT: X{1}  = a trials x features matrix for training. 
%            X{2} = a trials x features x samples matrix for testing
%            Y{n}  = a trials x 1 vector containing the class labels
%            cfg   = a configuration structure with the fields:
%                .nMeanS = amount of sample points to average over, default
%                is 0.
%                .gamma  = the shrinkage regularisation parameter for the
%                LDA classification
%    OUTPUT: Xhat  = sample point x test trials matrix of decoder
%    activations
%    See also TRAIN_LDA, DECODE_LDA
%


nSamplesTest = size(X{2},3);
nTrialsTest   = size(X{2},1);
nMeanS        = cfg.nMeanS;

Xhat          = zeros(nSamplesTest,nTrialsTest);
 
% define the training set
train = X{1};

for s1 = 1:nSamplesTest

     % define the training set
    if s1 <= nMeanS/2 || s1 >= nSamplesTest - (nMeanS/2)
        Xhat(s1,:) = NaN;
    else

        if sum(isnan(train(1,:))) > 1
                Xhat(s1,:) = NaN;
        else
        
            if mod(s1,100) == 0
            fprintf('\t Testing on sample %d out of %d \r',s1,nSamplesTest);
            end
            
            % train the decoder
            decoder = train_LDA(cfg, Y{1}, train');
            
            %test decoder on all samples of test fold
            test = squeeze(mean(X{2}(:,:,round(s1 - nMeanS/2):round(s1 + nMeanS/2)),3));
        
            % decoding
            Xhat(s1,:) = decode_LDA(cfg, decoder, test');
            
        end 
    end
end
end



