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

% Add SPM
addpath('D:\scripts\spm12');
spm('defaults', 'eeg')
addpath('D:\Github\OPM');

%%
cd('D:\Documents\GB_mesh');
MRI = 'D:\Documents\GB_mesh\GB.nii';
MRI_MEMES = 'D:\Documents\GB_mesh\MEMES_MRI_trans.nii';
headshape_file = 'D:\Documents\GB_mesh\headshape_downsampled_MRI.pos';

%% With MRI

S =[];
S.data = 'D:\sub-001_ses-001_task-motor_run-001_meg.bin';
%S.coordystem='coordsystem.json';
S.positions='D:\sub-001_ses-001_task-motor_run-001_positions.tsv';
S.channels='D:\sub-001_ses-001_task-motor_run-001_channels.tsv';
S.meg='D:\sub-001_ses-001_task-motor_run-001_meg.json';
S.sMRI=MRI;
S.precision='single';
D = spm_opm_create(S);

D_MRI = D;
D_MRI.save
clear D

%% With Headshape Warping in SPM
S =[];
S.data = 'D:\sub-001_ses-001_task-motor_run-001_meg.bin';
%S.coordystem='coordsystem.json';
S.template      = 1;
S.headshape     = headshape_file;
S.positions='D:\sub-001_ses-001_task-motor_run-001_positions.tsv';
S.channels='D:\sub-001_ses-001_task-motor_run-001_channels.tsv';
S.meg='D:\sub-001_ses-001_task-motor_run-001_meg.json';
S.precision='single';
D = spm_opm_create(S);
D_headshape_warp = D;
clear D


% %% With Just Fiducials in SPM
% S =[];f
% S.data = 'sub-001_ses-001_task-motor_run-001_meg.bin';
% S.coordystem='coord.json';
% S.template      = 1;
% %S.headshape     = 'headshape_downsampled_MRI_fids.pos';
% S.positions='sub-001_ses-001_task-motor_run-001_positions.tsv';
% S.channels='sub-001_ses-001_task-motor_run-001_channels.tsv';
% S.meg='sub-001_ses-001_task-motor_run-001_meg.json';
% S.precision='single';
% D = spm_opm_create(S);
% D_headshape_warp_fids = D;
% clear D

%% Using MEMES MRI
S =[];
S.data = 'D:\sub-001_ses-001_task-motor_run-001_meg.bin';
%S.coordystem='coordsystem.json';
S.positions='D:\sub-001_ses-001_task-motor_run-001_positions.tsv';
S.channels='D:\sub-001_ses-001_task-motor_run-001_channels.tsv';
S.meg='D:\sub-001_ses-001_task-motor_run-001_meg.json';
S.sMRI=MRI_MEMES;
S.precision='single';
D = spm_opm_create(S);

D_MEMES = D;
D_MEMES.save
clear D

%% Load Headshape in Same Space as MRI
headshape = 'headshape_downsampled.pos';

cfg = [];
cfg.verbose = 'no';
[warped_spm_mesh, trans_fids, warp_params] = TPS_warp(cfg,headshape);






%%
colin_head = ft_read_headshape('D:\Github\OPM\testData\scalp_extended_4098.surf.gii')

figure; ft_plot_mesh(colin_head,'facealpha',0.3,'edgecolor','none','facecolor','skin'); hold on;
ft_plot_headshape(headshape,'vertexcolor','r');

%% Do Initial Transform Based on Fiducials

% Get the fiducials in the right order
targetOrder = {'nas','lpa','rpa'};
[tf, loc] = ismember(lower(headshape.fid.label),targetOrder')
headshape.fid.label = headshape.fid.label(loc,:);
headshape.fid.pos = headshape.fid.pos(loc,:);

elec2common  = ft_headcoordinates(headshape.fid.pos(1,:),...
    headshape.fid.pos(2,:), ...
    headshape.fid.pos(3,:));

fids_SPM = [1  85 -41;-83 -20 -65; 83 -20 -65];

templ2common = ft_headcoordinates(fids_SPM(1,:),...
    fids_SPM(2,:), ...
    fids_SPM(3,:));

% compute the combined transform
norm         = [];
norm.m       = templ2common \ elec2common;

% % apply the transformation to the fiducials as sanity check
fids_SPM = ft_warp_apply(inv(norm.m),fids_SPM,'homogenous');
 
colin_head_transform = ft_transform_geometry(inv(norm.m),colin_head);

figure; 
ft_plot_mesh(colin_head_transform,'facealpha',0.3);
ft_plot_headshape(headshape,'vertexcolor','r');
camlight;
ft_plot_mesh(fids_SPM,'vertexcolor','g','vertexsize',20)

%% Spherical Harmonics
destPts = headshape.pos;

fvh = hsdig2fv(destPts, 5, 15, 10*pi/180, 0);
fvh.vertices = fvh.vertices;
% % 
destPts = fvh.vertices;
center = mean(destPts);

figure; ft_plot_mesh(colin_head_transform,'facealpha',0.2); hold on;
ft_plot_mesh(destPts,'vertexcolor','r');
ft_plot_mesh(center,'vertexcolor','g','vertexsize',20);

%% Make srcSurf = colin_head_transform
srcSurf           = [];
srcSurf.Vertices  = colin_head_transform.pos;
srcSurf.Faces     = colin_head_transform.tri;


%%
% Source landmarks: Project remeshed digitized surface on scalp
[srcPts, dist] = project_on_surface(srcSurf, destPts, center);

figure;
%ft_plot_mesh(srcSurf,'facealpha',0.2); hold on;
ft_plot_mesh(destPts,'vertexcolor','b','vertexsize',10); hold on;
ft_plot_mesh(srcPts,'vertexcolor','r','vertexsize',20);
ft_plot_mesh(center,'vertexcolor','g','vertexsize',20);
for i = 1:length(destPts)
    xyz = vertcat(srcPts(i,:),destPts(i,:));
    plot3(xyz(:,1),xyz(:,2),xyz(:,3),'k-');
end

camlight;

%% Compute Warp
[W,A] = warp_transform(srcPts, destPts); 

%% Further warp fiducial-aligned Colin Head to Headshape Points
sSurfNew.Faces    = srcSurf.Faces;
sSurfNew.Vertices = warp_lm(srcSurf.Vertices, A, W, srcPts) + srcSurf.Vertices;
%sSurfNew.Comment  = [srcSurf.Comment ' warped'];

tess_out_ft     = [];
tess_out_ft.pos = sSurfNew.Vertices;
tess_out_ft.tri = sSurfNew.Faces;

figure;
ft_plot_mesh(tess_out_ft,'facecolor', 'skin',...
    'edgecolor', 'none','facealpha',0.6); hold on;
ft_plot_headshape(headshape,'vertexcolor','r'); hold on;
camlight; hold on;

%% Load SPM canonical mesh and warp using:
% 1. Fiducial Warp
% 2. Headshape Warp
spm_mesh = ft_read_headshape('D:\scripts\spm12\canonical\cortex_5124.surf.gii');

spm_mesh_trans = ft_transform_geometry(inv(norm.m),spm_mesh);

figure;
ft_plot_mesh(spm_mesh_trans,'facecolor', 'b',...
    'edgecolor', 'none','facealpha',0.6); hold on;
ft_plot_headshape(headshape,'vertexcolor','r'); hold on;
view([90 0]); camlight; 
view([-90 0]); camlight;
title('Fiducial Warped')

spm_mesh_trans2 = spm_mesh_trans;
spm_mesh_trans2.pos = warp_lm(spm_mesh_trans.pos, A, W, srcPts) + spm_mesh_trans.pos;

figure;
ft_plot_mesh(spm_mesh_trans2,'facecolor', 'b',...
    'edgecolor', 'none','facealpha',0.8); hold on;
ft_plot_mesh(tess_out_ft,'facecolor', 'skin',...
    'edgecolor', 'none','facealpha',0.4); hold on;
ft_plot_headshape(headshape,'vertexcolor','r'); hold on;
view([90 0]); camlight; 
view([-90 0]); camlight; 
title('Fiducial + Headshape Warped');


%% Plot Results
mesh1     = D_MRI.inv{1}.forward.mesh;
mesh1.tri = mesh1.face;
mesh1.pnt = mesh1.vert*1000;

mesh2         = [];
mesh2.tri     = spm_mesh_trans.tri;
mesh2.pnt     = spm_mesh_trans.pos;

mesh3     = D_headshape_warp.inv{1}.forward.mesh;
mesh3.tri = mesh3.face;
mesh3.pnt = mesh3.vert*1000;

mesh4         = [];
mesh4.tri     = spm_mesh_trans2.tri;
mesh4.pnt     = spm_mesh_trans2.pos;

mesh5 = D_MEMES.inv{1}.forward.mesh;
mesh5.tri = mesh5.face;
mesh5.pnt = mesh5.vert*1000;

figure; 
ft_plot_mesh(mesh1,'facecolor','r','facealpha',0.1);
ft_plot_mesh(mesh2,'facecolor','b','facealpha',0.1); hold on;
ft_plot_mesh(mesh3,'facecolor','g','facealpha',0.1); hold on;
ft_plot_mesh(mesh4,'facecolor','y','facealpha',0.1); hold on;
ft_plot_mesh(mesh5,'facecolor','c','facealpha',0.1); hold on;
ft_plot_headshape(headshape,'vertexcolor','r');

warping_ways = {'FIDS','Affine_Headshape','TPS_Headshape','MEMES'}

figure;
set(gcf,'Position',[200 100 1800 550])

error = [];

for i = 1:length(warping_ways)

    % Calculate difference
    d = mesh1.pnt-eval(['mesh' num2str(i+1) '.pnt']);
    D = sqrt(sum(d.^2,2));

    error(i,:) = D;


    subplot(2,4,i);
    ft_plot_mesh(export(gifti(D_MRI.inv{1}.mesh.tess_ctx),'ft'),'vertexcolor',D,'facecolor',D,'facealpha',0.8);
    caxis([0 15]);
    title(warping_ways{i},'Interpreter','None');
    colorbar;
    view([-90 0]);


    subplot(2,4,i+4);
    ft_plot_mesh(export(gifti(D_MRI.inv{1}.mesh.tess_ctx),'ft'),'vertexcolor',D,'facecolor',D,'facealpha',0.8);
    caxis([0 15]);
    colorbar;
    view([0 0]);


end


figure; boxplot(error');







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
