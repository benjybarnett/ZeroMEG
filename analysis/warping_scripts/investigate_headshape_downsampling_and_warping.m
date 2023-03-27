%%
% Quick investigation for headshape warping for OPMs
%__________________________________________________________________________
% Copyright (C) 2021 Wellcome Trust Centre for Neuroimaging

% Authors:  Robert Seymour      (rob.seymour@ucl.ac.uk) 
%__________________________________________________________________________

%% Add analyse_OPMEG and 3Dscanning
% addpath(genpath('Users/rseymoue/Documents/GitHub/analyse_OPMEG'));
% addpath(genpath('/Users/rseymoue/Documents/GitHub/3Dscanning'));

addpath(genpath('D:\Github\analyse_OPMEG'));
addpath(genpath('D:\Github\3Dscanning'));

%%
cd('D:\Documents\GB_mesh');
MRI = 'D:\Documents\GB_mesh\GB.nii';
MRI_MEMES = 'D:\Documents\GB_mesh\MEMES_MRI_trans.nii';
headshape_file = 'D:\Documents\GB_mesh\headshape_downsampled_MRI.pos';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This bit of code is for transforming the headshape data from the ipad
% headshape into the same space as the participant's MRI for quality
% checking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
path_to_data = 'D:\Documents\GB_mesh';
path_to_ply  = 'gb_edit_hollow.ply';

cd(path_to_data);

%% Load data
head_surface = ft_read_headshape('gb_edit_hollow_ctf.ply');
% Add in fids info (not necessary but nice to have)
T = readtable('fids_ctf.csv');
head_surface.fid.pos = table2array(T(1:3,2:4));
head_surface.fid.label = {'NASION','LPA','RPA'};

% Plot
figure; ft_plot_mesh(head_surface); camlight;
ft_plot_mesh(head_surface.fid.pos,'vertexcolor','g','vertexsize',20)

%% Load Rob's MRI and create a mesh
% Change path to match your MRI
mri          = ft_read_mri('GB.nii');
mri.coordsys = 'neuromag';

cfg = [];
ft_sourceplot(cfg,mri);

%% Extract Scalp Surface from the MRI and create a mesh
cfg                     = [];
cfg.output              = 'scalp';
cfg.scalpsmooth         = 5;
cfg.scalpthreshold      = 0.08; % Change this value if the mesh looks weird
scalp                   = ft_volumesegment(cfg, mri);

% Create mesh
cfg                     = [];
cfg.method              = 'isosurface';
cfg.numvertices         = 10000;
mesh                    = ft_prepare_mesh(cfg,scalp);
mesh                    = ft_convert_units(mesh,'mm');

% Plot Mesh
figure;
ft_plot_mesh(mesh,'facecolor',[238,206,179]./255,'EdgeColor','none',...
    'facealpha',0.8); camlight; drawnow;
ft_plot_mesh(head_surface); camlight;

%% Rotate ipad surface by 180deg

ttt = cos(90*(pi/180));
rrr = sin(90*(pi/180));

trans = [ttt -rrr 0 0;
    rrr ttt 0 0;
    0 0 1 0;
    0 0 0 1];

head_surface2 = head_surface;
head_surface2.pos = ft_warp_apply(trans,head_surface2.pos);

% Plot Mesh
figure;
ft_plot_mesh(mesh,'facecolor',[238,206,179]./255,'EdgeColor','none',...
    'facealpha',0.8); camlight; drawnow;
ft_plot_mesh(head_surface2); camlight;

%% ICP
disp('Performing ICP');
[R, t, err] = icp(mesh.pos', head_surface2.pos', 50, ...
    'Minimize', 'plane', 'Extrapolation', true,...
    'WorstRejection', 0.1);

% Create figure to display how the ICP algorithm reduces error
clear plot;
figure; plot([1:1:51]',err,'LineWidth',8);
ylabel('Error'); xlabel('Iteration');
title('Error*Iteration');
set(gca,'FontSize',25);

% Create transformation matrix
trans2 = inv([real(R) real(t);0 0 0 1]);

%% Create figure to assess accuracy of coregistration
head_surface2_spare = head_surface2;
head_surface2_spare.pos = ft_warp_apply(inv(trans2), head_surface2_spare.pos);

% Figure 1
figure;
ft_plot_mesh(head_surface2_spare,'facecolor','r','facealpha',0.1); hold on;
ft_plot_mesh(mesh,'facecolor','b','facealpha',0.1); view([90 0]);


%% Downsample Headshape
cfg                                 = [];
cfg.facial_info                     = 'yes';
cfg.downsample_facial_info          = 'yes';
cfg.downsample_facial_info_amount   = 13;
cfg.facial_info_below_x             = 60;
cfg.facial_info_below_z             = 20;
cfg.remove_zlim                     = 0;
cfg.rotate                          = 0;
headshape_downsampled               = downsample_headshape_FIL(cfg,head_surface);

% Save Un-Warped One
write_pos('headshape_downsampled.pos',...
        headshape_downsampled);

% Warp twice
headshape_downsampled.pos = ft_warp_apply(trans,headshape_downsampled.pos);
headshape_downsampled.pos = ft_warp_apply(inv(trans2),headshape_downsampled.pos);
headshape_downsampled.fid.pos = ft_warp_apply(trans,headshape_downsampled.fid.pos);
headshape_downsampled.fid.pos = ft_warp_apply(inv(trans2),headshape_downsampled.fid.pos);


% Plot
figure;
ft_plot_headshape(headshape_downsampled,'vertexcolor','r');hold on;
ft_plot_mesh(mesh,'facealpha',0.1); view([90 0]); camlight; hold on;
%ft_plot_mesh(head_surface2_spare,'facealpha',0.1); 

% Save headshape_downsampled
save headshape_downsampled_MRI headshape_downsampled
write_pos('headshape_downsampled_MRI.pos',...
        headshape_downsampled);


% %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % TPS Warping
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %% Load Headshape in Same Space as MRI
% headshape = 'headshape_downsampled_MRI.pos';
% 
% cfg = [];
% cfg.verbose = 'yes';
% cfg.sph_harm = 'no';
% [warped_spm_mesh, trans_fids, warp_params] = TPS_warp(cfg,headshape);
% 
% %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % 12 Parameter Affine (SPM)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% headshape = 'headshape_downsampled_MRI.pos';
% 
% cfg                 = [];
% cfg.verbose         = 'yes';
% [warped_mesh_t, M1] = param_12_affine(cfg,headshape);
% 
% %% Plot Results
% % mesh1     = D_MRI.inv{1}.forward.mesh;
% % mesh1.tri = mesh1.face;
% % mesh1.pnt = mesh1.vert*1000;
% 
% mesh2         = [];
% mesh2.tri     = warped_spm_mesh.tri;
% mesh2.pnt     = warped_spm_mesh.pos;
% 
% mesh3         = [];
% mesh3.tri     = warped_mesh_t.tri;
% mesh3.pnt     = warped_mesh_t.pos;
% 
% 
% figure; 
% ft_plot_mesh(mesh1,'facecolor','r','facealpha',0.1);
% ft_plot_mesh(mesh2,'facecolor','b','facealpha',0.1); hold on;
% ft_plot_mesh(mesh3,'facecolor','g','facealpha',0.1); hold on;
% %ft_plot_headshape(headshape,'vertexcolor','r');
% 
% 
% error = [];
% 
% % Calculate difference
% d = mesh1.pnt-mesh2.pnt;
% D = sqrt(sum(d.^2,2));
% 
% error(1,:) = D;
% 
% 
% figure;
% set(gcf,'Position',[200 100 1800 550]);
% 
% subplot(1,2,1);
% ft_plot_mesh(mesh2,'vertexcolor',D,'facecolor',D,'facealpha',0.8);
% caxis([0 15]);
% colorbar;
% view([-90 0]);
% 
% subplot(1,2,2);
% ft_plot_mesh(mesh2,'vertexcolor',D,'facecolor',D,'facealpha',0.8);
% caxis([0 10]);
% colorbar;
% view([0 30]);
% 
% figure; histogram(error',20);
% set(gca,'FontSize',16)
% xlabel('Error (mm)','FontSize',20);
% ylabel('Count','FontSize',20);

%% Load sourcemodel from MRI
load('D:\Github\scannercast\examples\GRB\sourcemodel_5mm.mat');
sourcemodel_MRI = sourcemodel; clear sourcemodel;


%% Transform the template sourcemodel
[ftver, ftpath] = ft_version;
load(fullfile(ftpath,'template','sourcemodel','standard_sourcemodel3d5mm.mat'));
sourcemodel_headshape = sourcemodel; clear sourcemodel;
sourcemodel_headshape = ft_convert_units(sourcemodel_headshape,'mm');

% Warp sourcemodel 5mm grid using 12 affine
cfg = [];
cfg.verbose = 'no';
cfg.method = 'fids';
[sourcemodel_headshape1, M1] = param_12_affine(cfg,...
    headshape,sourcemodel_headshape);

% Warp sourcemodel 5mm grid using TPS
headshape = 'headshape_downsampled_MRI.pos';

cfg = [];
cfg.verbose = 'no';
cfg.sph_harm = 'no';
[sourcemodel_headshape2, trans_fids, warp_params] = TPS_warp(cfg,...
    headshape,sourcemodel_headshape);

% Warp sourcemodel 5mm grid using 12 affine
cfg = [];
cfg.verbose = 'no';
[sourcemodel_headshape3, M1] = param_12_affine(cfg,...
    headshape,sourcemodel_headshape);

% Warp sourcemodel based on the MEMES MRI
cfg                         = [];
cfg.grid.warpmni            = 'yes';
cfg.grid.resolution         = 5;
cfg.grid.nonlinear          = 'yes'; % use non-linear normalization
cfg.mri                     = mri_MEMES;
cfg.grid.unit               ='mm';
cfg.inwardshift             = '-1.5';
cfg.spmversion              = 'spm12';
sourcemodel_headshape4      = ft_prepare_sourcemodel(cfg);

%% Compare
figure; 
ft_plot_mesh(sourcemodel_MRI.pos(sourcemodel_MRI.inside(:),:),'vertexcolor','k'); hold on;
% ft_plot_mesh(sourcemodel_headshape1.pos(sourcemodel_headshape1.inside(:),:),'vertexcolor','b'); hold on;
% ft_plot_mesh(sourcemodel_headshape2.pos(sourcemodel_headshape2.inside(:),:),'vertexcolor','r'); hold on;
% ft_plot_mesh(sourcemodel_headshape3.pos(sourcemodel_headshape3.inside(:),:),'vertexcolor','g'); hold on;
ft_plot_mesh(sourcemodel_headshape4.pos(sourcemodel_headshape4.inside(:),:),'vertexcolor','y'); hold on;

%% Load sourcemodel from MEMES

error = [];

d = (sourcemodel_MRI.pos(sourcemodel_MRI.inside(:),:)) - (sourcemodel_headshape1.pos(sourcemodel_MRI.inside(:),:));
D = sqrt(sum(d.^2,2));

error(1,:) = D;


d = (sourcemodel_MRI.pos(sourcemodel_MRI.inside(:),:)) - (sourcemodel_headshape2.pos(sourcemodel_MRI.inside(:),:));
D = sqrt(sum(d.^2,2));

error(2,:) = D;

figure; histogram(error(1,:)',20); hold on;
histogram(error(2,:)',20); hold on;

d = (sourcemodel_MRI.pos(sourcemodel_MRI.inside(:),:)) - (sourcemodel_headshape3.pos(sourcemodel_MRI.inside(:),:));
D = sqrt(sum(d.^2,2));

error(3,:) = D;

d = (sourcemodel_MRI.pos(sourcemodel_MRI.inside(:),:)) - (sourcemodel_headshape4.pos(sourcemodel_MRI.inside(:),:));
D = sqrt(sum(d.^2,2));

error(4,:) = D;

figure; histogram(error(1,:)',50,'EdgeAlpha',0,'FaceAlpha',0.2); hold on;
histogram(error(2,:)',50,'EdgeAlpha',0,'FaceAlpha',0.2); hold on;
histogram(error(3,:)',50,'EdgeAlpha',0,'FaceAlpha',0.2); hold on;
histogram(error(4,:)',50,'EdgeAlpha',0,'FaceAlpha',0.2); hold on;
legend({'FIDS','TPS','12 PARAM AFFINE','MEMES'},'Location','eastoutside');
set(gca,'FontSize',18);
ylabel('Count','FontSize',20);
xlabel('Error (mm)','FontSize',20);












%% Load sourcemodel from MRI
load('D:\Github\scannercast\examples\RS\sourcemodel_5mm.mat');
sourcemodel_MRI = sourcemodel; clear sourcemodel;


%% MEMES
% Path to MEMES
% Download from https://github.com/FIL-OPMEG/MEMES
path_to_MEMES = ['/Users/rseymoue/Documents/GitHub/MEMES/'];
addpath(genpath(path_to_MEMES));
% Path to MRI Library for MEMES
path_to_MRI_library = '/Volumes/Robert T5/new_HCP_library_for_MEMES/';

MEMES_FIL(cd,headshape_downsampled,...
    path_to_MRI_library,'best',1,5,3);

mri_realigned_MEMES = ft_read_mri('mri_realigned_MEMES.nii');
mri_realigned_MEMES.coordsys    = 'bti';

%% Make headmodel
cfg           = [];
cfg.output    = 'brain';
segmentedmri  = ft_volumesegment(cfg, mri_realigned_MEMES);

cfg = [];
cfg.method='singleshell';
headmodel = ft_prepare_headmodel(cfg, segmentedmri);
save headmodel headmodel

figure; ft_plot_headmodel(headmodel,'edgecolor', 'none','facecolor','b','facealpha',0.3); 
ft_plot_mesh(head_surface,'facealpha',0.3); view([0 0]);
ft_plot_headshape(headshape_downsampled);

%%
sourcemodel_size = [5 8 10];

for i = 1:length(sourcemodel_size)
    disp(['Creating ' num2str(sourcemodel_size(i)) 'mm sourcemodel']);
    cfg                         = [];
    cfg.grid.warpmni            = 'yes';
    cfg.grid.resolution         = sourcemodel_size(i);
    cfg.grid.nonlinear          = 'yes'; % use non-linear normalization
    cfg.mri                     = mri_realigned_MEMES;
    cfg.grid.unit               ='mm';
    cfg.inwardshift             = '-1.5';
    cfg.spmversion              = 'spm12';
    sourcemodel                 = ft_prepare_sourcemodel(cfg);
    
    figure;
    ft_plot_headmodel(headmodel,'facealpha',0.3,'edgecolor', 'none');
    ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:));
    view([0 0]);
    print(['sourcemodel_qc_' num2str(sourcemodel_size(i)) 'mm'],'-dpng','-r300');
    
    save(['sourcemodel_' num2str(sourcemodel_size(i)) 'mm'],'sourcemodel');
end


%% Load sourcemodel from MEMES
load('sourcemodel_5mm.mat');
sourcemodel_MEMES = sourcemodel; clear sourcemodel;

d = (sourcemodel_MRI.pos(sourcemodel_MRI.inside(:),:)) - (sourcemodel_MEMES.pos(sourcemodel_MRI.inside(:),:));
D = sqrt(sum(d.^2,2));

figure; boxplot(D);

figure; ft_plot_mesh(mesh,'facealpha',0.1); hold on;
%ft_plot_mesh((sourcemodel_MRI.pos(sourcemodel_MRI.inside(:),:)),'vertexsize',1);
ft_plot_mesh((sourcemodel_MEMES.pos(sourcemodel_MEMES.inside(:),:)),'vertexcolor','r','vertexsize',1);












%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This bit of code is for transforming the headshape data from the ipad
% headshape into the same space as the participant's MRI for quality
% checking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
path_to_data = 'D:\Documents\GB_mesh';
path_to_ply  = 'gb_edit_hollow.ply';

cd(path_to_data);

%% Load data
head_surface = ft_read_headshape('gb_edit_hollow_ctf.ply');
% Add in fids info (not necessary but nice to have)
T = readtable('fids_ctf.csv');
head_surface.fid.pos = table2array(T(1:3,2:4));
head_surface.fid.label = {'NASION','LPA','RPA'};

% Plot
figure; ft_plot_mesh(head_surface); camlight;
ft_plot_mesh(head_surface.fid.pos,'vertexcolor','g','vertexsize',20)

%% Load Rob's MRI and create a mesh
% Change path to match your MRI
mri          = ft_read_mri('GB.nii');
mri.coordsys = 'neuromag';

cfg = [];
ft_sourceplot(cfg,mri);

%% Extract Scalp Surface from the MRI and create a mesh
cfg                     = [];
cfg.output              = 'scalp';
cfg.scalpsmooth         = 5;
cfg.scalpthreshold      = 0.08; % Change this value if the mesh looks weird
scalp                   = ft_volumesegment(cfg, mri);

% Create mesh
cfg                     = [];
cfg.method              = 'isosurface';
cfg.numvertices         = 10000;
mesh                    = ft_prepare_mesh(cfg,scalp);
mesh                    = ft_convert_units(mesh,'mm');

% Plot Mesh
figure;
ft_plot_mesh(mesh,'facecolor',[238,206,179]./255,'EdgeColor','none',...
    'facealpha',0.8); camlight; drawnow;
ft_plot_mesh(head_surface); camlight;

%% Rotate ipad surface by 180deg

ttt = cos(90*(pi/180));
rrr = sin(90*(pi/180));

trans = [ttt -rrr 0 0;
    rrr ttt 0 0;
    0 0 1 0;
    0 0 0 1];

head_surface2 = head_surface;
head_surface2.pos = ft_warp_apply(trans,head_surface2.pos);

% Plot Mesh
figure;
ft_plot_mesh(mesh,'facecolor',[238,206,179]./255,'EdgeColor','none',...
    'facealpha',0.8); camlight; drawnow;
ft_plot_mesh(head_surface2); camlight;

%% ICP
disp('Performing ICP');
[R, t, err] = icp(mesh.pos', head_surface2.pos', 50, ...
    'Minimize', 'plane', 'Extrapolation', true,...
    'WorstRejection', 0.2);

% Create figure to display how the ICP algorithm reduces error
clear plot;
figure; plot([1:1:51]',err,'LineWidth',8);
ylabel('Error'); xlabel('Iteration');
title('Error*Iteration');
set(gca,'FontSize',25);

% Create transformation matrix
trans2 = inv([real(R) real(t);0 0 0 1]);

%% Create figure to assess accuracy of coregistration
head_surface2_spare = head_surface2;
head_surface2_spare.pos = ft_warp_apply(inv(trans2), head_surface2_spare.pos);

% Figure 1
figure;
ft_plot_mesh(head_surface2_spare,'facecolor','r','facealpha',0.1); hold on;
ft_plot_mesh(mesh,'facecolor','b','facealpha',0.1); view([90 0]);


%% Downsample Headshape
cfg                                 = [];
cfg.facial_info                     = 'no';
cfg.downsample_facial_info          = 'yes';
cfg.downsample_facial_info_amount   = 13;
cfg.facial_info_below_x             = 60;
cfg.facial_info_below_z             = 20;
cfg.remove_zlim                     = -40;
cfg.rotate                          = -25;
headshape_downsampled               = downsample_headshape_FIL(cfg,head_surface);

% Save Un-Warped One
write_pos('headshape_downsampled.pos',...
        headshape_downsampled);

% Warp twice
headshape_downsampled.pos = ft_warp_apply(trans,headshape_downsampled.pos);
headshape_downsampled.pos = ft_warp_apply(inv(trans2),headshape_downsampled.pos);
headshape_downsampled.fid.pos = ft_warp_apply(trans,headshape_downsampled.fid.pos);
headshape_downsampled.fid.pos = ft_warp_apply(inv(trans2),headshape_downsampled.fid.pos);


% Plot
figure;
ft_plot_headshape(headshape_downsampled,'vertexcolor','r');hold on;
ft_plot_mesh(mesh,'facealpha',0.1); view([90 0]); camlight; hold on;
%ft_plot_mesh(head_surface2_spare,'facealpha',0.1); 

% Save headshape_downsampled
save headshape_downsampled_MRI headshape_downsampled
write_pos('headshape_downsampled_MRI.pos',...
        headshape_downsampled);

    
% Load the MRI from MEMES and transform to same space as GB.nii
mri_MEMES = ft_read_mri('mri_realigned_MEMES.nii');
mri_MEMES.coordsys = 'ctf';

ft_determine_coordsys(mri_MEMES,'interactive','no'); hold on;
ft_plot_mesh(mesh,'facealpha',0.1); view([90 0]); camlight; hold on;

% Warp twice
mri_MEMES = ft_transform_geometry(trans,mri_MEMES);
mri_MEMES = ft_transform_geometry(inv(trans2),mri_MEMES);

ft_determine_coordsys(mri_MEMES,'interactive','no'); hold on;
ft_plot_mesh(mesh,'facealpha',0.6); view([90 0]); camlight; hold on;

% Save MRI
cfg = [];
cfg.parameter = 'anatomy';
cfg.filename  = 'MEMES_MRI_trans';
cfg.filetype  = 'nifti';
cfg.datatype = 'double';
ft_volumewrite(cfg,mri_MEMES);

th = linspace(0,pi,50);    % inclination
phi = linspace(0,2*pi,50); % azimuth
[th,phi] = meshgrid(th,phi);



bnd = headshape_downsampled; nl = 5;

figure;

bnd2 = [];

% calculate midpoint
Or = mean(bnd.pos);
% rescale all points
x = bnd.pos(:,1) - Or(1);
y = bnd.pos(:,2) - Or(2);
z = bnd.pos(:,3) - Or(3);
X = [x(:), y(:), z(:)];

% convert points to parameters
[T,P] = points2param(X);

% basis function
B     = shlib_B(nl, T, P);
Y     = B'*X;

% solve the linear system
a_headshape     = pinv(B'*B)*Y;

figure; plot(a_headshape);

error_term = [];

%%
cd('/Volumes/Robert T5/new_HCP_library_for_MEMES/100307');
load('mesh.mat');

bnd = mesh; nl = 5;

bnd2 = [];

% calculate midpoint
Or = mean(bnd.pos);
% rescale all points
x = bnd.pos(:,1) - Or(1);
y = bnd.pos(:,2) - Or(2);
z = bnd.pos(:,3) - Or(3);
X = [x(:), y(:), z(:)];

% convert points to parameters
[T,P] = points2param(X);

% basis function
B     = shlib_B(nl, T, P);
Y     = B'*X;

% solve the linear system
a     = pinv(B'*B)*Y;


err = real(a_headshape)-real(a)


%%

figure; ft_plot_mesh(headshape_downsampled.pos);
ft_plot_mesh(mesh);

error_term_all = [];

Z = calculate_SPHARM_basis(headshape_downsampled.pos, 5);

for i=1:size(headshape_downsampled.pos,2)
    fvec1(:,i) = Z\headshape_downsampled.pos(:,i);
end

for t = 1:95
   disp(t);
%     load(fullfile(path_to_MRI_library, subject{t}, 'mesh.mat'));
%     
%     
%     Z = calculate_SPHARM_basis(mesh.pos, 5);
%     
%     for i=1:size(headshape_downsampled.pos,2)
%         fvec2(:,i) = Z\mesh.pos(:,i);
%     end
    
    load(fullfile(path_to_MRI_library, subject{t}, 'fvec2.mat'));

    error_term_all(t) = SPHARM_rmsd(fvec1, fvec2);
    clear fvec2 mesh
end




[M,I] = min(error_term_all)

load(fullfile(path_to_MRI_library, subject{I}, 'mesh.mat'));

figure; ft_plot_mesh(mesh,'facealpha',0.2); hold on;
        ft_plot_mesh(headshape_downsampled);


figure; scatter(error_term,error_term_all);
[R,P] = corrcoef(error_term,error_term_all)





%% MEMES
% Path to MEMES
% Download from https://github.com/Macquarie-MEG-Research/MEMES
path_to_MEMES = ['/Users/rseymoue/Documents/GitHub/MEMES/'];
addpath(genpath(path_to_MEMES));
% Path to MRI Library for MEMES
path_to_MRI_library = '/Volumes/Robert T5/new_HCP_library_for_MEMES/';

MEMES_FIL(cd,headshape_downsampled,...
    path_to_MRI_library,'best',1,8,3)

%% Load in MRI from MEMES
mri_realigned_MEMES = ft_read_mri('mri_realigned_MEMES.nii');
mri_realigned_MEMES.coordsys    = 'bti';

%% Make headmodel
cfg           = [];
cfg.output    = 'brain';
segmentedmri  = ft_volumesegment(cfg, mri_realigned_MEMES);

cfg = [];
cfg.method='singleshell';
headmodel = ft_prepare_headmodel(cfg, segmentedmri);
save headmodel headmodel

figure; ft_plot_headmodel(headmodel,'edgecolor', 'none','facecolor','b','facealpha',0.3); 
ft_plot_mesh(head_surface,'facealpha',0.3); view([0 0]);
%%
sourcemodel_size = [5 8 10];

for i = 1:length(sourcemodel_size)
    disp(['Creating ' num2str(sourcemodel_size(i)) 'mm sourcemodel']);
    cfg                         = [];
    cfg.grid.warpmni            = 'yes';
    cfg.grid.resolution         = sourcemodel_size(i);
    cfg.grid.nonlinear          = 'yes'; % use non-linear normalization
    cfg.mri                     = mri_realigned_MEMES;
    cfg.grid.unit               ='mm';
    cfg.inwardshift             = '-1.5';
    cfg.spmversion              = 'spm12';
    sourcemodel                 = ft_prepare_sourcemodel(cfg);
    
    figure;
    ft_plot_headmodel(headmodel,'facealpha',0.3,'edgecolor', 'none');
    ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:));
    ft_plot_mesh(head_surface,'facealpha',0.2);
    view([0 0]);
    print(['sourcemodel_qc_' num2str(sourcemodel_size(i)) 'mm'],'-dpng','-r300');
    
    save(['sourcemodel_' num2str(sourcemodel_size(i)) 'mm'],'sourcemodel');
end
