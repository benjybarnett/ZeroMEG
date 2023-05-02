function [headmodel_new,sourcemodel_new,grad,pos,template_source] = ForwardModel(cfg0,subject)
    % Function Name: Forward
    %
    % The Forward function takes the default head and source models from FieldTrip
    % and warps them to subject-specific fiducials. The function keeps the gradiometer
    % info for subsequent use in ft_sourceanalysis.
    %
    % The function has four output arguments:
    %
    % headmodel_new: a struct containing the warped head model
    % sourcemodel_new: a struct containing the warped source model
    % grad: a struct containing the gradiometer information
    % pos: a matrix containing the positions of the template source model
    % The function has two input arguments:
    %
    % cfg0: a struct containing the configuration options for the function
    % subject: a string containing the subject identifier

    %Author: Benjy Barnett 2023
    
    %% 1. Create Head Model
    
    raw_data_dir = fullfile(cfg0.rawDir,subject,'\meg\raw');
    dataSets = str2fullfile(raw_data_dir,'*sf025*');
    raw_data = dataSets{1};

    fids = ft_read_headshape(raw_data);
    fids = ft_convert_units(fids,'mm');

    sens = ft_read_header(raw_data);
    sens = sens.grad;
    grad = ft_convert_units(sens,'mm');

    %figure; ft_plot_sens(sens); hold on; ft_plot_headshape(fids);

    [~, ftpath] = ft_version;
    
    % Load SPM Mesh with 5124 vertices
    load(fullfile(ftpath,...
        'template','headmodel','standard_singleshell.mat'));
    headmodel = vol; clear vol;
    
    headmodel = ft_convert_units(headmodel,'mm');
    
    cfg = [];
    cfg.method = 'fids';
    cfg.verbose = 'no';
    [warped_mesh_t, M1] = param_12_affine(cfg,...
        raw_data,headmodel.bnd);
    
    headmodel_new = headmodel;
    headmodel_new.bnd = warped_mesh_t;
    
    %figure; ft_plot_sens(sens); hold on; ft_plot_headshape(fids); hold on;
    %ft_plot_headmodel(headmodel_new);


    %% Now Source Model
    load(fullfile(ftpath,...
        'template','sourcemodel','standard_sourcemodel3d8mm.mat'));
    sourcemodel = ft_convert_units(sourcemodel,'mm');
    template_source = sourcemodel;

    cfg = [];
    cfg.method = 'fids';
    cfg.verbose = 'no';
    [warped_mesh_sourcemodel, ~] = param_12_affine(cfg,...
        raw_data,sourcemodel);

    sourcemodel_new = warped_mesh_sourcemodel;
    %inside = sourcemodel_new.inside;
    %sourcemodel_new.inside = logical(ones(length(sourcemodel_new.inside),1)); % this has to be changed to work with ft_virtualchannels
    %pos = sourcemodel.pos;
    
    %Trim outside brain parts
    sourcemodel_new.pos    = sourcemodel_new.pos(sourcemodel_new.inside,:);
    pos = template_source.pos(sourcemodel_new.inside,:); %store pos info from template source model
    sourcemodel_new.inside = sourcemodel.inside(sourcemodel_new.inside,:); % and update the inside vector itself


end