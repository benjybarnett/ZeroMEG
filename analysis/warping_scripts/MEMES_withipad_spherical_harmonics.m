%%
% Very rough pipeline for using MEMES with ipad scan.
%__________________________________________________________________________
% Copyright (C) 2021 Wellcome Trust Centre for Neuroimaging

% Authors:  Robert Seymour      (rob.seymour@ucl.ac.uk) 
%__________________________________________________________________________

%% Add analyse_OPMEG
addpath(genpath('Users/rseymoue/Documents/GitHub/analyse_OPMEG'));

%%
path_to_data = '/Users/rseymoue/Downloads/OneDrive_1_23-06-2021';
path_to_ply  = 'export123.ply';

cd(path_to_data);

%% Load data
head_surface_bti = ft_read_headshape('export123_bti.ply');
% Add in fids info (not necessary but nice to have)
T = readtable('fids_bti.csv');
head_surface_bti.fid.pos = table2array(T(1:3,2:4));
head_surface_bti.fid.label = {'NASION','LPA','RPA'};

%% Downsample Headshape
cfg                                 = [];
cfg.downsample_facial_info          = 'yes';
cfg.downsample_facial_info_amount   = 13;
cfg.facial_info_below_x             = 60;
cfg.facial_info_below_z             = 20;

headshape_downsampled       = downsample_headshape_FIL(cfg,head_surface_bti);
headshape_downsampled       = rmfield(headshape_downsampled,'tri');


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
ft_plot_mesh(head_surface_bti,'facealpha',0.3); view([0 0]);
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
    ft_plot_mesh(head_surface_bti,'facealpha',0.2);
    view([0 0]);
    print(['sourcemodel_qc_' num2str(sourcemodel_size(i)) 'mm'],'-dpng','-r300');
    
    save(['sourcemodel_' num2str(sourcemodel_size(i)) 'mm'],'sourcemodel');
end
