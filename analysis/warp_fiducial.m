figure;ft_plot_sens(data.grad)
ds = dataSets{1};
fids = ft_read_headshape(ds);
fids = ft_convert_units(fids,'mm');

sens = data.grad;
sens = ft_convert_units(sens,'mm');

figure; ft_plot_sens(sens); hold on; ft_plot_headshape(fids);

[~, ftpath] = ft_version;

% Load SPM Mesh with 5124 vertices
load(fullfile(ftpath,...
    'template','headmodel','standard_singleshell.mat'));
headmodel = vol; clear vol;

headmodel = ft_convert_units(headmodel,'mm');

cfg = [];
cfg.method = 'fids';
cfg.verbose = 'yes';
[warped_mesh_t, M1] = param_12_affine(cfg,...
    ds,headmodel.bnd);

headmodel_new = headmodel;
headmodel_new.bnd = warped_mesh_t;

figure; ft_plot_sens(sens); hold on; ft_plot_headshape(fids); hold on;
ft_plot_headmodel(headmodel_new);


%% now source model
load(fullfile(ftpath,...
    'template','sourcemodel','standard_sourcemodel3d8mm.mat'));
sourcemodel = ft_convert_units(sourcemodel,'mm');

cfg = [];
cfg.method = 'fids';
cfg.verbose = 'yes';
[warped_mesh_sourcemodel, ~] = param_12_affine(cfg,...
    ds,sourcemodel);

sourcemodel_new = warped_mesh_sourcemodel;

figure; ft_plot_sens(sens); hold on; ft_plot_headshape(fids); hold on;
ft_plot_headmodel(headmodel_new); hold on; ft_plot_mesh(sourcemodel_new);
