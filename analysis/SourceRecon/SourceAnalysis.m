function [virtual_channels] = SourceAnalysis(cfg0)
    
    %Function Name: SourceAnalysis
    % 
    % Description: This MATLAB function performs source analysis on MEG data using FieldTrip toolbox. The function computes virtual channels for each condition specified in the configuration file, given as the first input argument. The function saves the virtual channels for each condition in a file and returns the virtual channels and the average source reconstruction.
    % 
    % Inputs:
    % 
    % cfg0: A structure containing the configuration information for source analysis. The structure includes fields such as:
    % 
    % outdir: The directory where the output files will be saved.
    % datadir: The directory where the MEG data is saved.
    % grad: The sensor geometry (in the format of FieldTrip grad structure) used for MEG recording.
    % sourcemodel: The sourcemodel used for source reconstruction.
    % headmodel: The headmodel used for source reconstruction.
    % condition_trls: A cell array containing the trial definitions for each condition.
    % pos: the original template sourcemodel pos info
    % subject: The subject identifier (string).
    % 
    % Outputs:
    % 
    % virtual_channels: A cell array containing the virtual channels for each condition.
    % source_avg: The average source reconstruction for all conditions.

    %Author: Benjy Barnett 2023

    %% Source Analysis

    %outputDir = fullfile(cfg0.outdir,subject);
    %if ~isfolder(outputDir);mkdir(outputDir);end

    data = load(cfg0.datadir); %fullfile('D:\bbarnett\Documents\Zero\data\CleanData\',subject,'\dot_trials.mat'
    data = struct2cell(data);data = data{1};
    cfg = [];
    cfg.channel = 'meg';
    %cfg.latency = [0.1 0.5]; %select latency of interest
    meg_data = ft_selectdata(cfg,data);
    clear data
    
    meg_data.grad = cfg0.grad; %For ft_sourcenalaysis, data needs grad structure

    %if ~isfolder(fullfile(outputDir,'FullSource'))
        disp('Performing Source Reconstruction Over All Conditions')
        % Compute Covariance Matrix
        cfg = [];
        cfg.covariance = 'yes';
        avg = ft_timelockanalysis(cfg,meg_data);
    
        %calculate kappa (from fieldtrip tutorial)
        [u,s,v] = svd(avg.cov);
        d       = -diff(log10(diag(s)));
        d       = d./std(d);
        kappa   = find(d>5,1,'first');
    
        %Calculate spatial filter for each voxel over all data
        cfg = [];
        cfg.method = 'lcmv';
        cfg.sourcemodel = cfg0.sourcemodel;
        cfg.headmodel = cfg0.headmodel;
        cfg.lcmv.keepfilter = 'yes';
        cfg.lcmv.kappa = kappa;
        cfg.lcmv.lambda = '5%'; %try changing this - and try changing kappa
        cfg.lcmv.weightnorm = 'unitnoisegain';
        cfg.lcmv.fixedori = 'yes'; %try changing this
        cfg.channel = {'MEG'};
        cfg.senstype = 'MEG';
        sourceavg = ft_sourceanalysis(cfg, avg);
        sourceavg.pos = cfg0.pos; %set grid positions back to template sourcemodel grid
        
        %mkdir(fullfile(outputDir,'FullSource'))
        %save(fullfile(outputDir,'FullSource',cfg0.avgSourceOut),'sourceavg');
    
        clear sourcemodel headmodel avg
     
        %{
    else
        disp('Loading Previously Computed Sources Over All Conditions')
        load(fullfile(outputDir,'FullSource',cfg0.avgSourceOut))
    end
        %}
        
    
%    if ~isfile(fullfile(outputDir,'cond_vChannels.mat'))
        virtual_channels = cell(6,1);
        for condition = 1:length(cfg0.condition_trls)
            fprintf('\n\n Computing Virtual Channels for Condition %d \n\n',condition)
            cfg = [];
            cfg.trials = eval(cfg0.condition_trls{condition});
            cfg.showcallinfo= 'no';
            data = ft_selectdata(cfg,meg_data);
    
            

            cfg = [];
            cfg.covariance = 'yes';
            cfg.keeptrials = 'yes';
            cfg.showcallinfo= 'no';
            cond_trials = ft_timelockanalysis(cfg,data);
            clear data
    
            %Average samples to increase signal to noise and reduce trials for source recon
            fprintf('Averaging Samples in groups of %d \n\n', cfg0.group_size)
            pparam.group_size = cfg0.group_size;
            [~, cond_trials.trial, ~] = mv_preprocess_average_samples(pparam, cond_trials.trial, ones(size(cond_trials.trial,1),1));
            cond_trials = ft_timelockanalysis(cfg,cond_trials); %recomputes cov matrix over reduced/averaged trials
    
            %Get the virtual channels
            cfg = [];
            cfg.showcallinfo='no';
            cfg.pos = sourceavg.pos;
            cond_source = ft_virtualchannel(cfg,cond_trials,sourceavg); %using filters built from all conditions
            virtual_channels{condition,1} = cond_source;
            clear cond_trials cond_source
        end
        clear meg_data
        %% Save
        %disp('Saving Condition-Specific Virtual Channels...')
        %Not saving because files are so large and saving/loading takes nearly as much time as just re-running the code
        %save(fullfile(outputDir,'cond_vChannels.mat'),'virtual_channels','-v7.3');
        
   %{
    else
        disp('Loading Previously Computed Condition-Specific Virtual Channels')
        load(fullfile(outputDir,'cond_vChannels.mat'))
    end
   %}
   
end