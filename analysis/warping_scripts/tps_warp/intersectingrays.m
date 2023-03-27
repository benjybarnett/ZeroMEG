%%
% Work in progress pipeline for warping canonical template mesh 
% to the ipad headshape (based on template spline warping).
%__________________________________________________________________________
% Copyright (C) 2021 Wellcome Trust Centre for Neuroimaging

% Authors:  Robert Seymour      (rob.seymour@ucl.ac.uk) 
%__________________________________________________________________________

%% Add analyse_OPMEG
addpath(genpath('Users/rseymoue/Documents/GitHub/analyse_OPMEG'));

%% Add MEMES
addpath(genpath('/Users/rseymoue/Documents/GitHub/MEMES'));

%% Paths
path_to_data = '/Users/rseymoue/Documents/test_child';
path_to_ply  = 'test_child_ctf.ply';

cd(path_to_data);

%% Load .ply file
head_surface = ft_read_headshape(path_to_ply);
head_surface = ft_convert_units(head_surface,'mm');

figure; ft_plot_headshape(head_surface);

%% Load data
% Add in fids info (not necessary but nice to have)
T = readtable('fids_ctf.csv');
head_surface.fid.pos = table2array(T(1:3,2:4));
head_surface.fid.label = {'NASION','LPA','RPA'};

%% Downsample Headshape
cfg                                 = [];
cfg.facial_info                     = 'no';
cfg.downsample_facial_info_amount   = 16;
cfg.facial_info_below_x             = 60;
cfg.facial_info_below_z             = 0;

headshape_downsampled       = downsample_headshape_FIL(cfg,head_surface);
headshape_downsampled       = rmfield(headshape_downsampled,'tri');

figure; ft_plot_headshape(headshape_downsampled);

%%
headshape_downsampled = head_surface;

rrr = headshape_downsampled.pos(:,3) < 0;

headshape_downsampled.pos(rrr,:) = [];
headshape_downsampled            = rmfield(headshape_downsampled,'tri');

figure; ft_plot_headshape(headshape_downsampled);

%% Load the SPM canonical scalp mesh
try
    disp('Loading SPM canonical mesh (scalp)...');
    path_to_SPM_mesh = ...
        which('scalp_2562.surf.gii');

colin_head = ft_read_headshape(path_to_SPM_mesh);
colin_head = ft_convert_units(colin_head,'mm');

figure; 
ft_plot_mesh(colin_head,'facealpha',0.3);
ft_plot_mesh(headshape_downsampled,'vertexcolor','r');
camlight;
catch
    warning('Cannot find scalp_2562.surf.gii');
end

%% Do initial realign using the Fieldtrip's ft_interactiverealign.m
cfg = [];
cfg.template.headshape      = colin_head;
cfg.checksize               = inf;
cfg.individual.headshape    = headshape_downsampled;
cfg                         = ft_interactiverealign(cfg);
trans                       = cfg.m;
colin_head_transform        = ft_transform_geometry(inv(cfg.m), colin_head);

figure; 
ft_plot_mesh(colin_head_transform,'facealpha',0.3);
ft_plot_mesh(headshape_downsampled,'vertexcolor','r');
camlight;



%%
destPts = headshape_downsampled.pos;
% 
% % % % SPherical Harmonics?
fvh = hsdig2fv(destPts, 5, 15, 10*pi/180, 0);
fvh.vertices = fvh.vertices;
% % 
destPts = fvh.vertices;
center = mean(destPts);

figure; ft_plot_mesh(colin_head_transform,'facealpha',0.2); hold on;
ft_plot_mesh(destPts,'vertexcolor','r');
ft_plot_mesh(center,'vertexcolor','g','vertexsize',20);

%%   
P = destPts;
Q = 0.*P;

for i = 1:length(P)
    %disp(i);
    [points, pos, indx] = intersect_line(colin_head_transform.pos,...
        colin_head_transform.tri, P(i,:), center);
    
    % If there is only one intersection point
    if size(points,1) == 1
        
        try
            % Get distance between intersection point to P
            % ... and P to center
            P_to_point = pdist2(points,P(i,:));
            P_to_cent = pdist2(points,center);
            
            % If P_to_point > P_to_cent the ray must be inside
            if P_to_point>P_to_cent
                % Therefore look at ray going in opposite direction
                [points, pos, indx] = intersect_line(colin_head_transform.pos,...
                    colin_head_transform.tri,center,P(i,:));
            end
        catch
        end
    end
    
    if size(points) == 1
        Q(i,:) = points;
    end
    
    % If multiple intersection points
    if size(points,1) > 1
        % Find distance between intersection points
        dist1 = pdist2(points(1,:),P(i,:));
        dist2 = pdist2(points(2,:),P(i,:));
        
        % Only pick the shortest
        if dist1 > dist2
            Q(i,:) = points(2,:);
        else
            Q(i,:) = points(1,:);
        end
        
        % If there are no intersections, warn the user
    elseif isempty(points)
        warning(['No intersecting rays for point ' num2str(i)]);
        Q(i,:) = P(i,:);
        
        % If only one intersection point, add this to Q
    else
        Q(i,:) = points;
    end

end

%% Mak a Figure to Show Results
figure;
ft_plot_mesh(colin_head_transform,'facealpha',0.3);
ft_plot_mesh(P,'vertexcolor','b','vertexsize',10); hold on;
ft_plot_mesh(Q,'vertexcolor','r','vertexsize',20);
ft_plot_mesh(center,'vertexcolor','g','vertexsize',20);
for i = 1:length(P)
    xyz = vertcat(P(i,:),Q(i,:));
    plot3(xyz(:,1),xyz(:,2),xyz(:,3),'k-');
end

%%
[W,A] = warp_transform(Q, P); 

% Warp surface
colin_head_transform2 = colin_head_transform;

sSurfNew.Faces    = colin_head_transform.tri;
colin_head_transform2.pos = warp_lm(colin_head_transform2.pos, A, W, Q) + colin_head_transform2.pos;
%sSurfNew.Comment  = [srcSurf.Comment ' warped'];


figure;
ft_plot_mesh(colin_head_transform2,'facecolor', 'skin',...
    'edgecolor', 'none','facealpha',0.5); hold on;
ft_plot_mesh(headshape_downsampled,'vertexcolor','r','vertexsize',20); hold on;

%% Now let's apply the same warps to headmodel/sourcemodel

% Load headmodel
[t, r] = ft_version;
ddd = load(fullfile(r,'template/headmodel/standard_singleshell.mat'));
headmodel=ft_convert_units(ddd.vol,'mm');
clear ddd

% Transform headmodel
headmodel.bnd.pos = ft_warp_apply(inv(trans),headmodel.bnd.pos);
headmodel.bnd.pos = warp_lm(headmodel.bnd.pos, A, W, Q) + headmodel.bnd.pos;

% Load sourcemodel (5mm)
[t, r] = ft_version;
ddd = load(fullfile(r,'template/sourcemodel/standard_sourcemodel3d5mm.mat'));
sourcemodel=ft_convert_units(ddd.sourcemodel,'mm');
clear ddd

% Transform sourcemodel
sourcemodel.pos = ft_warp_apply(inv(trans),sourcemodel.pos);
sourcemodel.pos = warp_lm(sourcemodel.pos, A, W, Q) + sourcemodel.pos;

% Make Figure
figure;
ft_plot_headmodel(headmodel,'facecolor', 'skin',...
    'edgecolor', 'none','facealpha',0.5); hold on;
ft_plot_mesh(colin_head_transform2,'facecolor', 'k',...
    'edgecolor', 'none','facealpha',0.05); hold on;
ft_plot_mesh(headshape_downsampled,'vertexcolor','r','vertexsize',20); hold on;
ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:),...
    'vertexsize',2,'vertexcolor','k');
camlight;

% Make Figure 2
figure;
ft_plot_headmodel(headmodel,'facecolor', 'skin',...
    'edgecolor', 'none','facealpha',0.5); hold on;
ft_plot_mesh(head_surface,'facealpha',0.5); hold on;
ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:),...
    'vertexsize',2,'vertexcolor','k');
camlight;

%%
save headmodel headmodel
save sourcemodel sourcemodel
save colin_head_transform2 colin_head_transform2







