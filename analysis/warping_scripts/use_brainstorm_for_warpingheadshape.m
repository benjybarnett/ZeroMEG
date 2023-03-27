%%
% Very rough pipeline for using Brainstorm for nonlinear warp
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
head_surface_bti = ft_read_headshape('rs_edit_bti.ply');
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
headshape_downsampled       = downsample_headshape_FIL(cfg,...
    head_surface_bti);

headshape_downsampled       = rmfield(headshape_downsampled,'tri');

save headshape_downsampled headshape_downsampled

cd('/Users/rseymoue/Downloads/OneDrive_1_23-06-2021');
load('headshape_downsampled.mat');


%% Add Brainstorm to path
restoredefaultpath
cd('/Users/rseymoue/Documents/scripts/brainstorm3');
brainstorm

%% Create dummy Channels File
Comment = 'RS_dummy_chans'
MegRefCoef = [];
Projector = struct();
TransfMeg       = [];
TransfEeg       = [];
TransfEegLabels = [];

cd('/Users/rseymoue/Documents/GitHub/scannercast/examples/RS');
tsv_info = in_tsv('dummy_channels.tsv',{'name','type','units','status'});
tsv_pos = in_tsv('dummy_positions.tsv',{'name','Px','Py','Pz','Ox','Oy','Oz'});

Channel = [];

for i = 1:length(tsv_pos)

Channel(i).Loc = [str2double(tsv_pos{i,2}); ...
    str2double(tsv_pos{i,3});...
    str2double(tsv_pos{i,4})]/100;

Channel(i).Orient = [str2double(tsv_pos{i,5}); ...
    str2double(tsv_pos{i,6});...
    str2double(tsv_pos{i,7})];

Channel(i).Comment = 'Mag';

Channel(i).Weight = 1;

Channel(i).Type = 'MEG';

Channel(i).Name = char(tsv_pos{i,1});


end

% Now add in Headshape
HeadPoints = [];
HeadPoints.Loc = (headshape_downsampled.pos/100)';
HeadPoints.Label = repmat({'EXTRA'},1,length(headshape_downsampled.pos));
HeadPoints.Type = repmat({'EXTRA'},1,length(headshape_downsampled.pos));

% 
% HeadPoints.Label = {'Nasion','LPA','RPA'}
% HeadPoints.Type = {'CARDINAL','CARDINAL','CARDINAL'};

%HeadPoints.Loc = headshape_downsampled.pos;

SCS     = [];
SCS.NAS = [];
SCS.LPA = [];
SCS.RPA = [];
SCS.R   = [];
SCS.T   = [];


cd('/Users/rseymoue/Documents/OPM_data/data/Subject01');
save('dddd.mat','Channel','Comment','HeadPoints','SCS')


view_channels('/Users/rseymoue/Documents/OPM_data/data/Subject01/channel_file.mat','MEG');

Channel.Loc = tsv_info

%%
fvh = hsdig2fv(headshape_downsampled.pos, 5, 15/1000, 40*pi/180, 1);

%%
cd('/Users/rseymoue/Documents/scripts/brainstorm3/defaults/anatomy/ICBM152');
destPts = headshape_downsampled.pos;
load(fullfile(cd,OuterSkull))

sDefSubject = bst_get('Subject', 0);





%%
%headshape = ft_read_headshape('rs_edit_bti.ply');

srcSurf = in_tess_bst('/Users/rseymoue/Documents/scripts/brainstorm3/defaults/anatomy/ICBM152/tess_head.mat');
destPts = headshape_downsampled.pos/1000;

figure; ft_plot_mesh(srcSurf.Vertices); hold on;
ft_plot_mesh(destPts,'vertexcolor','r');

% % SPherical Harmonics?
% fvh = hsdig2fv(destPts, 5, 15/1000, 40*pi/180, 0);

%destPtsParam = destPts;
center = mean(destPts);
%destPts = fvh.vertices;

    
% figure; ft_plot_mesh(srcSurf.Vertices); hold on;
% ft_plot_mesh(fvh.vertices,'vertexcolor','r');

% Source landmarks: Project remeshed digitized surface on scalp
[srcPts, dist] = project_on_surface(srcSurf, destPts, center);

figure;ft_plot_mesh(srcSurf.Vertices); hold on;
%ft_plot_mesh(destPts,'vertexcolor','b','vertexsize',10); hold on;
ft_plot_mesh(srcPts,'vertexcolor','r','vertexsize',10);

SurfaceFilesFull = {'/Users/rseymoue/Documents/scripts/brainstorm3/defaults/anatomy/ICBM152/tess_head.mat'};
MriFileFull      = '/Users/rseymoue/Documents/scripts/brainstorm3/defaults/anatomy/ICBM152/subjectimage_T1.mat';
OutputDir = '/Users/rseymoue/Downloads/OneDrive_1_23-06-2021';

[OutputSurfaces, OutputMri] = bst_warp(destPts, srcPts,...
    SurfaceFilesFull, MriFileFull, '_output', OutputDir,0);

tess_out = in_tess_bst('/Users/rseymoue/Downloads/OneDrive_1_23-06-2021/tess_head_output.mat')
tess_out_ft = [];
tess_out_ft.pos = tess_out.Vertices;
tess_out_ft.tri = tess_out.Faces;
tess_out_ft.unit = 'm';

headshape_downsampled = ft_convert_units(headshape_downsampled,'m');

figure; ft_plot_mesh(tess_out,'facecolor', 'skin',...
    'edgecolor', 'none','facealpha',0.7); hold on;
ft_plot_mesh(headshape_downsampled,...
    'vertexsize',15,'vertexcolor','b'); hold on;

%% Now let's try to do this ourselves

[W,A] = warp_transform(srcPts, destPts); 

% Warp surface
sSurfNew.Faces    = srcSurf.Faces;
sSurfNew.Vertices = warp_lm(srcSurf.Vertices, A, W, srcPts) + srcSurf.Vertices;
sSurfNew.Comment  = [srcSurf.Comment ' warped'];

tess_out_ft = [];
tess_out_ft.pos = sSurfNew.Vertices;
tess_out_ft.tri = sSurfNew.Faces;
tess_out_ft.unit = 'm';

figure;
ft_plot_mesh(tess_out,'facecolor', 'skin',...
    'edgecolor', 'none','facealpha',0.5); hold on;
%ft_plot_mesh(headshape_downsampled,'facealpha',0.3,'vertexcolor','r'); hold on;
ft_plot_mesh(headshape,'facealpha',0.5);

%% OK let's try and do the same in Fieldtrip

%% Make hollow Colin
% colin_head_original = ft_read_headshape(...
%     '/Users/rseymoue/Documents/scripts/fieldtrip-20210506/template/headmodel/skin/standard_skin_1222.vol');
% 
% ft_write_headshape('colin_head',colin_head_original,'format','ply')
% 
% colin_head = ft_read_headshape('/Users/rseymoue/Documents/scripts/spm12/canonical/scalp_2562.surf.gii');
% %colin_head = ft_read_headshape('/Users/rseymoue/colin_head_hollow3.ply');
% ft_write_headshape('spm_head',colin_head,'format','ply')

%%
colin_head = ft_read_headshape('/Users/rseymoue/spm_head_hollow.ply');

figure;
ft_plot_mesh(colin_head,'facealpha',0.3)

figure; 
ft_plot_mesh(colin_head,'facealpha',0.3);
ft_plot_mesh(headshape_downsampled,'vertexcolor','r');
camlight;


cfg = [];
cfg.template.headshape      = colin_head;
cfg.checksize               = inf;
cfg.individual.headshape    = headshape_downsampled;
cfg                         = ft_interactiverealign(cfg);
trans                       = cfg.m;
colin_head_transform        = ft_transform_geometry(inv(cfg.m), colin_head);

headshape_downsampled = ft_convert_units(headshape_downsampled,'mm');

figure; 
ft_plot_mesh(colin_head_transform,'facealpha',0.3);
ft_plot_mesh(headshape_downsampled,'vertexcolor','r');
camlight;

%%
destPts = headshape_downsampled.pos/1000;

% % % SPherical Harmonics?
fvh = hsdig2fv(destPts, 5, 15/1000, 40*pi/180, 0);
% 
destPtsParam = destPts;
destPts = fvh.vertices;
center = mean(destPts);

figure; ft_plot_mesh(colin_head_transform,'facealpha',0.2); hold on;
ft_plot_mesh(destPts*1000,'vertexcolor','r');
ft_plot_mesh(center,'vertexcolor','g','vertexsize',20);

srcSurf = [];
srcSurf.Vertices = colin_head_transform.pos/1000;
srcSurf.Faces    = colin_head_transform.tri;

% Source landmarks: Project remeshed digitized surface on scalp
[srcPts, dist] = project_on_surface(srcSurf, destPts, center);

figure;
%ft_plot_mesh(srcSurf,'facealpha',0.2); hold on;
ft_plot_mesh(destPts,'vertexcolor','b','vertexsize',10); hold on;
ft_plot_mesh(srcPts,'vertexcolor','r','vertexsize',20);
ft_plot_mesh(center,'vertexcolor','g','vertexsize',20);
for i = 1:length(destPts)
    xyz = vertcat(srcPts(i,:),destPts(i,:))
    plot3(xyz(:,1),xyz(:,2),xyz(:,3),'k-');
end

camlight;




%%
[W,A] = warp_transform(srcPts, destPts); 

% Warp surface
sSurfNew.Faces    = srcSurf.Faces;
sSurfNew.Vertices = warp_lm(srcSurf.Vertices, A, W, srcPts) + srcSurf.Vertices;
%sSurfNew.Comment  = [srcSurf.Comment ' warped'];

tess_out_ft = [];
tess_out_ft.pos = sSurfNew.Vertices;
tess_out_ft.tri = sSurfNew.Faces;
tess_out_ft.unit = 'm';

tess_out_ft = ft_convert_units(tess_out_ft,'mm');

figure;
ft_plot_mesh(tess_out_ft,'facecolor', 'skin',...
    'edgecolor', 'none','facealpha',0.5); hold on;
ft_plot_mesh(headshape_trans,'facealpha',0.3,'vertexcolor','r'); hold on;
camlight;












%%
fids_SPM = [1  85 -41;-83 -20 -65; 83 -20 -65];


headshape_downsampled = ft_convert_units(headshape_downsampled,'mm');

colin_head.coordsys = 'mni';

cfg                 = [];
cfg.method          = 'fiducial';
cfg.coordsys        = 'ctf';
cfg.fiducial.nas    = ([1  85 -41]); %position of NAS
cfg.fiducial.lpa    = ([-83 -20 -65]); %position of LPA
cfg.fiducial.rpa    = ([83 -20 -65]); %position of RPA
colin_head_bti    = ft_meshrealign(cfg,colin_head);

fids_SPM = [1  85 -41;-83 -20 -65; 83 -20 -65];

transform_ctf = ft_headcoordinates(cfg.fiducial.nas, ...
    cfg.fiducial.lpa, cfg.fiducial.rpa, 'ctf');

fids_SPM_warped = ft_warp_apply(transform_ctf,fids_SPM);


figure; 
ft_plot_mesh(colin_head_bti,'facealpha',0.3); hold on;
ft_plot_mesh(fids_SPM_warped,'vertexcolor','g');
camlight;

%%
cfg                 = [];
cfg.method          = 'fiducial';
cfg.target          = 'pos';
cfg.coordsys        = 'mni';
cfg.fiducial.nas    = (headshape_downsampled.fid.pos(1,:)); %position of NAS
cfg.fiducial.lpa    = (headshape_downsampled.fid.pos(2,:)); %position of LPA
cfg.fiducial.rpa    = (headshape_downsampled.fid.pos(3,:)); %position of RPA
headshape_downsampled_mni    = ft_electroderealign(cfg,headshape_downsampled);

%%
figure; 
%ft_plot_mesh(colin_head_bti,'facealpha',0.5);
ft_plot_mesh(head_surface_bti,'facealpha',0.3);
ft_plot_mesh(headshape_downsampled);
camlight;



