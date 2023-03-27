%%
% Very rough pipeline for using MEMES with ipad scan.
%__________________________________________________________________________
% Copyright (C) 2021 Wellcome Trust Centre for Neuroimaging

% Authors:  Robert Seymour      (rob.seymour@ucl.ac.uk) 
%__________________________________________________________________________


%% Load downsampled headshape and original mesh
headshape_downsampled = ft_read_headshape('headshape_downsampled_MRI.pos');
%head_surface = ft_read_headshape('scalp_external.stl');

%% MEMES
% Path to MEMES
% Download from https://github.com/FIL-OPMEG/MEMES
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
    ft_plot_mesh(head_surface,'facealpha',0.2);
    view([0 0]);
    print(['sourcemodel_qc_' num2str(sourcemodel_size(i)) 'mm'],'-dpng','-r300');
    
    save(['sourcemodel_' num2str(sourcemodel_size(i)) 'mm'],'sourcemodel');
end
