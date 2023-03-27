function [warped_mesh_t, trans_fids, warp_params] = TPS_warp(cfg,...
    headshape,varargin)
% Function to use thin-plate-spline (TPS) warping, to warp template anatomy
% (e.g. SPM mesh) to a downsampled headshape file
%
% EXAMPLE USEAGE:   [warped_mesh_t, trans] = TPS_warp(cfg,headshape);
% ...where, cfg is the input structure and headshape is the headshape file
% used for warping (must be read-able by ft_read_headshape)
%
%   cfg.sph_harm        = 'yes' or 'no' (default = 'no')
%   cfg.verbose         = 'yes' or 'no' (default = 'no')
%__________________________________________________________________________
% Copyright (C) 2021 Wellcome Trust Centre for Neuroimaging
% Adapted from bst_warp.m in Brainstorm

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
    
end


%% Defaults
sph_harm                  = ft_getopt(cfg,'sph_harm','no');
verbose                   = ft_getopt(cfg,'verbose','no');

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
%% Warp Colin based on fiducials
[colin_head_transform,trans_fids] = warp_spm_fid(headshape,colin_head);

if strcmp(verbose,'yes')
    fids_SPM = [1  85 -41;-83 -20 -65; 83 -20 -65];
    % % apply the transformation to the fiducials as sanity check
    fids_SPM = ft_warp_apply(trans_fids,fids_SPM,'homogenous');

    figure;
    ft_plot_mesh(colin_head_transform,'facealpha',0.3);
    ft_plot_headshape(headshape,'vertexcolor','r');
    view([90 0]);camlight;
    ft_plot_mesh(fids_SPM,'vertexcolor','g','vertexsize',20);

end



%% Spherical Harmonics
if strcmp(sph_harm,'yes')
    disp('Using Spherical Harmomics to get a smoooooth mesh')
    fvh = hsdig2fv(headshape.pos, 5, 15, 10*pi/180, 0);
    fvh.vertices = fvh.vertices;
    destPts = fvh.vertices;
else
    % Else make destPts = headshape.pos
    destPts = headshape.pos;
    
end
%% Make Centre
center = mean(destPts);

% Plot
if strcmp(verbose,'yes')
    figure; ft_plot_mesh(colin_head_transform,'facealpha',0.2); hold on;
    ft_plot_mesh(destPts,'vertexcolor','r');
    ft_plot_mesh(center,'vertexcolor','g','vertexsize',20);
end


%% Make srcSurf = colin_head_transform
srcSurf           = [];
srcSurf.Vertices  = colin_head_transform.pos;
srcSurf.Faces     = colin_head_transform.tri;


%% Project headshape onto scalp
[srcPts, dist] = project_on_surface(srcSurf, destPts, center);

% Plot
if strcmp(verbose,'yes')
    figure;
    ft_plot_mesh(destPts,'vertexcolor','b','vertexsize',10); hold on;
    ft_plot_mesh(srcPts,'vertexcolor','r','vertexsize',20);
    ft_plot_mesh(center,'vertexcolor','g','vertexsize',20);
    for i = 1:length(destPts)
        xyz = vertcat(srcPts(i,:),destPts(i,:));
        plot3(xyz(:,1),xyz(:,2),xyz(:,3),'k-');
    end
    view([90 0]); camlight;
end


%% Compute Warp
[W,A] = warp_transform(srcPts, destPts);


%% Further warp fiducial-aligned Colin Head to Headshape Points
sSurfNew.Faces    = srcSurf.Faces;
sSurfNew.Vertices = warp_lm(srcSurf.Vertices, A, W, srcPts) + srcSurf.Vertices;

tess_out_ft       = [];
tess_out_ft.pos   = sSurfNew.Vertices;
tess_out_ft.tri   = sSurfNew.Faces;

if strcmp(verbose,'yes')
    figure;
    ft_plot_mesh(tess_out_ft,'facecolor', 'skin',...
        'edgecolor', 'none','facealpha',0.6); hold on;
    ft_plot_headshape(headshape,'vertexcolor','r'); hold on;
    view([90 0]); camlight;
end


%% Warp mesh using:
% 1. Fiducial Warp
% 2. Headshape Warp

% Do the first transform
mesh_t_trans = ft_transform_geometry(trans_fids,mesh_t);

if strcmp(verbose,'yes')
    figure;
    ft_plot_mesh(mesh_t_trans,'facecolor', 'b',...
        'edgecolor', 'none','facealpha',0.6); hold on;
    ft_plot_headshape(headshape,'vertexcolor','r'); hold on;
    view([90 0]); camlight;
    view([-90 0]); camlight;
    title('Fiducial Warped');
end

% Do the second transform
warp_params           = warp_lm(mesh_t_trans.pos, A, W, srcPts);
warped_mesh_t         = mesh_t_trans;
warped_mesh_t.pos     = warp_params + mesh_t_trans.pos;

% Plot
if strcmp(verbose,'yes')

    figure;
    ft_plot_mesh(warped_mesh_t,'facecolor', 'b',...
        'edgecolor', 'none','facealpha',0.8); hold on;
    ft_plot_mesh(tess_out_ft,'facecolor', 'skin',...
        'edgecolor', 'none','facealpha',0.4); hold on;
    ft_plot_headshape(headshape,'vertexcolor','r'); hold on;
    view([90 0]); camlight;
    view([-90 0]); camlight;
    title('Fiducial + Headshape Warped');
end




    function [colin_head_transform,trans_fids] = warp_spm_fid(headshape,colin_head)
    % Function to warp the SPM canonical mesh based on fiducials supplied by
    % the headshape data
    elec2common  = ft_headcoordinates(headshape.fid.pos(1,:),...
        headshape.fid.pos(2,:), ...
        headshape.fid.pos(3,:));

    fids_SPM = [1  85 -41;-83 -20 -65; 83 -20 -65];

    templ2common = ft_headcoordinates(fids_SPM(1,:),...
        fids_SPM(2,:), ...
        fids_SPM(3,:));

    % compute the combined transform
    trans_fids       = inv(templ2common \ elec2common);

    colin_head_transform = ft_transform_geometry(trans_fids,colin_head);

    end

end

