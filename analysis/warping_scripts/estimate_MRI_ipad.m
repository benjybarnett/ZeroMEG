%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a work in progress pipeline for estimating an MRI based on the
% participant's head shape, as measured via the 3D scan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath(genpath('/Users/rseymoue/Documents/GitHub/MQ_MEG_Scripts'));
cd('/Users/rseymoue/Downloads/OneDrive_1_23-06-2021');
path_to_ply = 'export123.ply';

% Read head surface data
head_surface = ft_read_headshape(path_to_ply);

try
    cfg = [];
    cfg.channel = {'Nasion','Left PA','Right PA'};
    cfg.method = 'headshape';
    fiducials = ft_electrodeplacement_FIL(cfg,head_surface);
catch
    % Most likely the user will not have ft_electrodeplacement_FIL in the
    % right location. Try to correct this
    disp('Trying to move ft_electrodeplacement_FIL to the Fieldtrip directory');
    [ftver, ftpath] = ft_version();
    loc_of_ft_elecRS = which('ft_electrodeplacement_FIL2');
    copyfile(loc_of_ft_elecRS,ftpath);
    
    % Rename ft_electrodeplacement_RS2 to ft_electrodeplacement_RS
    movefile(fullfile(ftpath,'ft_electrodeplacement_FIL2.m'),...
        fullfile(ftpath,'ft_electrodeplacement_FIL.m'));
    
    cfg = [];
    cfg.channel = {'Nasion','Left PA','Right PA'};
    cfg.method = 'headshape';
    fiducials = ft_electrodeplacement_FIL(cfg,head_surface);
end


% Convert to BTI space
cfg = [];
cfg.method = 'fiducial';
cfg. coordsys = 'bti';
cfg.fiducial.nas    = fiducials.elecpos(1,:); %position of NAS
cfg.fiducial.lpa    = fiducials.elecpos(2,:); %position of LPA
cfg.fiducial.rpa    = fiducials.elecpos(3,:); %position of RPA
head_surface_bti    = ft_meshrealign(cfg,head_surface);

% Save fiducial information in BTI space
transform_bti = ft_headcoordinates(cfg.fiducial.nas, ...
    cfg.fiducial.lpa, cfg.fiducial.rpa, cfg.coordsys);

fids_for_mesh = ft_warp_apply(transform_bti,fiducials.elecpos);

% Add this info to .fid field
head_surface_bti.fid.pos = fids_for_mesh;
head_surface_bti.fid.label = {'NASION','LPA','RPA'};

% Plot figure
try
    figure;
    set(gcf,'Position',[100 100 1000 600]);
    subplot(1,2,1);
    ft_plot_axes(head_surface_bti);
    ft_plot_headshape(head_surface_bti);
    view([0,0]);
    subplot(1,2,2);
    ft_plot_axes(head_surface_bti);
    ft_plot_headshape(head_surface_bti);
    view([90,0]);
    print(['FIDS'],'-dpng','-r200');
catch
    disp('Could not plot')
end


%% Downsample Headshape
cfg                                 = [];
cfg.downsample_facial_info          = 'yes';
cfg.downsample_facial_info_amount   = 13;
cfg.facial_info_below_x             = 60;
cfg.facial_info_below_z             = 20;

headshape_downsampled = downsample_headshape_FIL(cfg,head_surface_bti);

%% MEMES
% Path to MEMES
% Download from https://github.com/Macquarie-MEG-Research/MEMES
path_to_MEMES = ['/Users/rseymoue/Documents/GitHub/MEMES/'];
addpath(genpath(path_to_MEMES));
% Path to MRI Library for MEMES
path_to_MRI_library = '/Volumes/Robert T5/new_HCP_library_for_MEMES/';

MEMES_FIL(cd,headshape_downsampled,...
    path_to_MRI_library,'best',1,8,3)


%% Make headmodel
load('mri_realigned_MEMES.mat');
cfg           = [];
cfg.output    = 'brain';
segmentedmri  = ft_volumesegment(cfg, mri_realigned_MEMES);

cfg           = [];
cfg.method    ='singleshell';
headmodel     = ft_prepare_headmodel(cfg, segmentedmri);

figure; ft_plot_headmodel(headmodel,'edgecolor', 'none','facecolor','b','facealpha',0.3); 
ft_plot_mesh(head_surface_bti,'facealpha',0.3);

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
    view([-90 0]);
    print(['sourcemodel_qc_' num2str(sourcemodel_size(i)) 'mm'],'-dpng','-r300');
    
    save(['sourcemodel_' num2str(sourcemodel_size(i)) 'mm'],'sourcemodel');
end

%%

figure;
ft_plot_headmodel(headmodel,'facealpha',0.3,'edgecolor', 'none');
%ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:));
ft_plot_mesh(head_surface_bti,'facealpha',0.2);
ft_plot_sens(grad_trans);
view([-90 0]);
   









%% Specify the location of the data
data_loc = '/Users/rseymoue/Documents/GitHub/scannercast/examples/RS/';
cd(data_loc)


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This bit is specific to RS: I want to check
% quality of the pseudo MRI versus ground truth
% (i.e. real MRI).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sens_loc = tsvread('sensor_locations.tsv');
pos     = [sens_loc.Px sens_loc.Py sens_loc.Pz];
ori     = [sens_loc.Ox sens_loc.Oy sens_loc.Oz];

grad = [];
grad.chanpos = pos;
grad.chanori = ori;
grad.label = sens_loc.filename;
grad.corresponding_sens = sens_loc.corresponding_sens;

pos_spare = pos;
ori_spare = ori;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% PART 3.2: Load in MRI and scalp mesh. Ideally this
%           SHOULD be the original version (not defaced).
%
% Optionally we can coregister the .stl scalp mesh 
% with the MRI scalp mesh if they are not aligned
% properly
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load in the MRI
mri = mri_realigned2; % RS_realigned.nii

%% Load in the stl file of the scalp surface
scalp_surface = ft_read_headshape('tes123.ply');

% Plot for quality control
figure; ft_plot_mesh(scalp_surface); camlight;

ft_determine_coordsys(mri, 'interactive', 'no');
hold on; % add the subsequent objects to the figure
drawnow; % workaround to prevent some MATLAB versions (2012b and 2014b) from crashing
hold on;
ft_plot_mesh(scalp_surface,'facealpha',0.3); camlight; hold on;
ft_plot_mesh(pos);

%% Rotate the scalp surface mesh -90 about z axis

ttt = cos(-90*(pi/180));
rrr = sin(-90*(pi/180));

trans = [ttt -rrr 0 0;
    rrr ttt 0 0;
    0 0 1 0;
    0 0 0 1];

scalp_surface.pos = ft_warp_apply(trans,scalp_surface.pos);

% % Check if this looks OK
ft_determine_coordsys(mri, 'interactive', 'no');
hold on; % add the subsequent objects to the figure
drawnow; % workaround to prevent some MATLAB versions (2012b and 2014b) from crashing
ft_plot_mesh(scalp_surface); camlight;

%% Extract Scalp Surface from the MRI and create a mesh
cfg                     = [];
cfg.output              = 'scalp';
cfg.scalpsmooth         = 5;
cfg.scalpthreshold      = 0.09; % Change this value if the mesh looks weird
scalp                   = ft_volumesegment(cfg, mri);

% Create mesh
cfg                     = [];
cfg.method              = 'isosurface';
cfg.numvertices         = 20000;
mesh                    = ft_prepare_mesh(cfg,scalp);
mesh                    = ft_convert_units(mesh,'mm');

% Plot Mesh
figure;
ft_plot_mesh(mesh,'facecolor',[238,206,179]./255,'EdgeColor','none',...
    'facealpha',0.8); camlight; drawnow;
ft_plot_mesh(scalp_surface); camlight;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Only do the rest of step 3.2 and 3.3 if the MRI scalp and the 
% aren't aligned. If they are already aligned simply run:
%
% grad_trans = grad;
%
% ... and skip to step 3.5
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Now use ICP to match the MRI mesh with the mesh
disp('Performing ICP');
[R, t, err] = icp(mesh.pos', scalp_surface.pos', 50, ...
    'Minimize', 'plane', 'Extrapolation', true,...
    'WorstRejection', 0.1);

% Create figure to display how the ICP algorithm reduces error
clear plot;
figure; plot([1:1:51]',err,'LineWidth',8);
ylabel('Error'); xlabel('Iteration');
title('Error*Iteration');
set(gca,'FontSize',25);

% Create transformation matrix
trans_matrix = inv([real(R) real(t);0 0 0 1]);

% Apply the transformations to the sensor positions
pos     = ft_warp_apply(trans,pos);
pos     = ft_warp_apply(inv(trans_matrix),pos);

%% Create figure to assess accuracy of coregistration
scalp_surface_spare = scalp_surface;
scalp_surface_spare.pos = ft_warp_apply(inv(trans_matrix), scalp_surface_spare.pos);

% Figure 1
figure;
ft_plot_mesh(scalp_surface_spare,'vertexcolor','r','facealpha',0.1); hold on;
ft_plot_mesh(mesh,'vertexcolor','b','facealpha',0.1); view([90 0]);

% Figure 2
ft_determine_coordsys(mri, 'interactive', 'no');
hold on; % add the subsequent objects to the figure
drawnow; % workaround to prevent some MATLAB versions (2012b and 2014b) from crashing
ft_plot_mesh(pos);
ft_plot_mesh(scalp_surface_spare,'facealpha',0.6)

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% PART 3.3: Transform the sensors using the transformation matrices
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


grad            = ft_transform_geometry(trans,grad);

grad_trans            = ft_transform_geometry(inv(trans_matrix),...
    grad);

figure; ft_plot_sens(grad_trans,'orientation','true'); hold on;
ft_plot_mesh(mesh,'facealpha',0.5);


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% PART 3.4: Here we are assuming the scannercast will be labelled the 
% SAME as the .stl numbers. If this changes, we can easily 
% change headcast2stl.csv

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create headcast2stl.csv file
Headcast    = (1:(size(pos)/2))';
STL         = (1:(size(pos)/2))';

t           = table(Headcast,STL);
writetable(t,'headcast2stl.csv','Delimiter',',','QuoteStrings',true)
clear t

headcast2stl = readtable('headcast2stl.csv');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% PART 3.5: Create table_of_info.csv file with position and 
% orientation information for RAD+TAN orientations
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make table_of_info file

table_of_info        = headcast2stl;
table_of_info.Px     = grad_trans.chanpos(1:length(grad_trans.chanpos)/2,1);
table_of_info.Py     = grad_trans.chanpos(1:length(grad_trans.chanpos)/2,2);
table_of_info.Pz     = grad_trans.chanpos(1:length(grad_trans.chanpos)/2,3);

table_of_info.Ox_RAD = grad_trans.chanori(contains(...
    grad_trans.corresponding_sens,'RAD'),1);
table_of_info.Oy_RAD = grad_trans.chanori(contains(...
    grad_trans.corresponding_sens,'RAD'),2);
table_of_info.Oz_RAD = grad_trans.chanori(contains(...
    grad_trans.corresponding_sens,'RAD'),3);

table_of_info.Ox_TAN = grad_trans.chanori(contains(...
    grad_trans.corresponding_sens,'TAN'),1);
table_of_info.Oy_TAN = grad_trans.chanori(contains(...
    grad_trans.corresponding_sens,'TAN'),2);
table_of_info.Oz_TAN = grad_trans.chanori(contains(...
    grad_trans.corresponding_sens,'TAN'),3);

% Save as table_of_info.csv
writetable(table_of_info,'table_of_info.csv',...
    'Delimiter',',','QuoteStrings',true)

%%

cfg           = [];
cfg.output    = 'brain';
segmentedmri  = ft_volumesegment(cfg, mri_realigned_MEMES);

cfg           = [];
cfg.method    ='singleshell';
headmodel     = ft_prepare_headmodel(cfg, segmentedmri);

figure; ft_plot_headmodel(headmodel,'edgecolor', 'none','facecolor','b','facealpha',0.3); 
ft_plot_mesh(head_surface_bti,'facealpha',0.3);

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
    view([-90 0]);
    print(['sourcemodel_qc_' num2str(sourcemodel_size(i)) 'mm'],'-dpng','-r300');
    
    save(['sourcemodel_' num2str(sourcemodel_size(i)) 'mm'],'sourcemodel');
end

%%

figure;
ft_plot_headmodel(headmodel,'facealpha',0.3,'edgecolor', 'none');
%ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:));
ft_plot_mesh(head_surface_bti,'facealpha',0.2);
ft_plot_sens(grad_trans);
view([-90 0]);
   




