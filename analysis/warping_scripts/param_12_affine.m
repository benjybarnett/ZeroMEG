function [warped_mesh_t, M1] = param_12_affine(cfg,...
    headshape,varargin)
% Function to use full twelve parameter affine mapping, to warp template 
% anatomy (e.g. SPM mesh) to a downsampled headshape file
%
% EXAMPLE USEAGE:   [warped_mesh_t, M1] = param_12_affine(cfg,headshape,...);
% ...where, cfg is the input structure and headshape is the headshape file
% used for warping (must be read-able by ft_read_headshape)
%
%   cfg.method        = 'full' or 'fids'  (default = 'full'). The 'fids'
%                        option just uses the fiducials rather than 
%                        doing any headshape warping
%   cfg.verbose         = 'yes' or 'no' (default = 'no')
%
%__________________________________________________________________________
% Copyright (C) 2021 Wellcome Trust Centre for Neuroimaging
% Adapted from spm_eeg_inv_datareg.m (SPM12)

% Authors:  Robert Seymour      (rob.seymour@ucl.ac.uk)
%__________________________________________________________________________

%% Deal with variable inputs
% If variable inputs are empty use defaults
if isempty(varargin)
    [~, ftpath] = ft_version;

    % Load SPM Mesh with 5124 vertices
    mesh_t = ft_read_headshape(fullfile(ftpath,...
        'template','sourcemodel','cortex_5124.surf.gii'));

else
    mesh_t    = varargin{1};
    %mesh_t    = ft_convert_units(mesh_t,'mm');
end

%% Defaults
verbose                   = ft_getopt(cfg,'verbose','no');
method                    = ft_getopt(cfg,'method','full');


%% Load Headshape
headshape = ft_read_headshape(headshape);
headshape = ft_convert_units(headshape,'mm');

% Put the fiducials in the right order
targetOrder = {'nas','lpa','rpa'};
[tf, loc] = ismember(lower(headshape.fid.label),targetOrder');
headshape.fid.label = headshape.fid.label(loc,:);
headshape.fid.pos = headshape.fid.pos(loc,:);


%% Load the extended Colin head made by GON

[name,~] = fileparts(which('TPS_warp'));
colin_head = ft_read_headshape(fullfile(name,'tps_warp',...
    'scalp_extended_4098.surf.gii'));

if strcmp(verbose,'yes')
    figure; ft_plot_mesh(colin_head,'facealpha',0.3,'edgecolor','none','facecolor','skin'); hold on;
    ft_plot_headshape(headshape,'vertexcolor','r');
    view([90 0]);
end


%% Make variables compliant with rest of function
targetfid.fid.pnt = headshape.fid.pos;
sourcefid.fid.pnt = [1  85 -41;-83 -20 -65; 83 -20 -65];

%% Estimate-apply rigid body transform to sensor space
%--------------------------------------------------------------------------
M1 = spm_eeg_inv_rigidreg(targetfid.fid.pnt', sourcefid.fid.pnt');
sourcefid = ft_transform_geometry(M1, sourcefid);


% constrained affine transform
%--------------------------------------------------------------------------
for i = 1:64

    % scale
    %----------------------------------------------------------------------
    M       = pinv(sourcefid.fid.pnt(:))*targetfid.fid.pnt(:);
    M       = sparse(1:4,1:4,[M M M 1]);

    sourcefid = ft_transform_geometry(M, sourcefid);

    M1      = M*M1;

    % and move
    %----------------------------------------------------------------------
    M       = spm_eeg_inv_rigidreg(targetfid.fid.pnt', sourcefid.fid.pnt');

    sourcefid = ft_transform_geometry(M, sourcefid);

    M1      = M*M1;

    if (norm(M)-1)< eps
        break;
    end
end

%% Apply this to Colin's head
colin_head_transform = ft_transform_geometry(M1,colin_head);

% Plot
if strcmp(verbose,'yes')
    figure;
    ft_plot_mesh(colin_head_transform,'facealpha',0.3);
    ft_plot_headshape(headshape,'vertexcolor','r');
    view([90 0]);camlight;
    ft_plot_mesh(sourcefid.fid.pnt,'vertexcolor','g','vertexsize',20);
    
end

% If headshape is going to be used for warping...
if strcmp(method,'full')

    %%
    % Surface matching between the scalp vertices in MRI space and the
    % headshape positions in data space
    headshape_pnt = headshape.pos;
    scalpvert     = colin_head_transform.pos;
    
    % Plot
    if strcmp(verbose,'yes')
        figure;
        Fmri = plot3(scalpvert(:,1),scalpvert(:,2),scalpvert(:,3),'ro','MarkerFaceColor','r');
        hold on;
        Fhsp = plot3(headshape_pnt(:,1),headshape_pnt(:,2),headshape_pnt(:,3),'bs','MarkerFaceColor','b');
        axis off image
        drawnow;
        view([-90 0])
    else
        Fmri = [];
        Fhsp = [];
    end

    % Apply the ICP
    M = spm_eeg_inv_icp(scalpvert',headshape_pnt',targetfid.fid.pnt',sourcefid.fid.pnt',Fmri,Fhsp,1);
    
    % Unsure why I need inv here, have I got something the wrong way
    % around?
    M1        = inv(M)*M1;

    %% Apply this to Colin's head
    colin_head_transform = ft_transform_geometry(M1,colin_head);

    % Plot
    if strcmp(verbose,'yes')
        figure;
        ft_plot_mesh(colin_head_transform,'facealpha',0.3);
        ft_plot_headshape(headshape,'vertexcolor','r');
        view([90 0]);camlight;
        ft_plot_mesh(sourcefid.fid.pnt,'vertexcolor','g','vertexsize',20);
    end
end

%% Transform and return the mesh
warped_mesh_t = ft_transform_geometry(M1,mesh_t);

% Plot
if strcmp(verbose,'yes')

    figure;
    ft_plot_mesh(warped_mesh_t,'facecolor', 'b',...
        'edgecolor', 'none','facealpha',0.8); hold on;
    ft_plot_mesh(colin_head_transform,'facecolor', 'skin',...
        'edgecolor', 'none','facealpha',0.4); hold on;
    ft_plot_headshape(headshape,'vertexcolor','r'); hold on;
    view([90 0]); camlight;
    view([-90 0]); camlight;
    title('Fiducial + Headshape Warped');
end








