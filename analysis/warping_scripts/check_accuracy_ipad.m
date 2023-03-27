%%
% Very rough script to check the accuracy of the 3D ipad scan versus the
% partcipant's structural MRI:
%__________________________________________________________________________
% Copyright (C) 2021 Wellcome Trust Centre for Neuroimaging

% Authors:  Robert Seymour      (rob.seymour@ucl.ac.uk) 
%__________________________________________________________________________

%%
path_to_data = '/Users/rseymoue/Downloads/OneDrive_1_23-06-2021';
path_to_ply  = 'rs_no_interal_faces.ply';

cd(path_to_data);

%% Load .ply file
head_surface = ft_read_headshape(path_to_ply);
head_surface = ft_convert_units(head_surface,'mm');

%% Mark the location of 3 fiducials using ft_electrodeplacement_FIL:
try
    cfg = [];
    cfg.channel = {'Nasion','Left PA','Right PA'};
    cfg.method = 'headshape';
    fiducials = ft_electrodeplacement_FIL(cfg,head_surface);
catch
    % Most likely the user will not have ft_electrodeplacement_FIL in the
    % right location. Try to correct this:
    disp('Trying to move ft_electrodeplacement_FIL to the Fieldtrip directory');
    [ftver, ftpath] = ft_version();
    loc_of_ft_elecRS = which('ft_electrodeplacement_FIL2');
    copyfile(loc_of_ft_elecRS,ftpath);
    
    % Rename ft_electrodeplacement_RS2 to ft_electrodeplacement_FIL
    movefile(fullfile(ftpath,'ft_electrodeplacement_FIL2.m'),...
        fullfile(ftpath,'ft_electrodeplacement_FIL.m'));
    
    cfg = [];
    cfg.channel = {'Nasion','Left PA','Right PA'};
    cfg.method = 'headshape';
    fiducials = ft_electrodeplacement_FIL(cfg,head_surface);
end

% Check if 3 points have been marked
if length(fiducials.label) ~= 3
    warning('Wrong number of points marked. Proceed with caution');
end

%% Convert to CTF space & save info
cfg                 = [];
cfg.method          = 'fiducial';
cfg.coordsys       = 'ctf';
cfg.fiducial.nas    = fiducials.elecpos(1,:); %position of NAS
cfg.fiducial.lpa    = fiducials.elecpos(2,:); %position of LPA
cfg.fiducial.rpa    = fiducials.elecpos(3,:); %position of RPA
head_surface_ctf       = ft_meshrealign(cfg,head_surface);

% Save fiducial information in BTI space
transform_ctf = ft_headcoordinates(cfg.fiducial.nas, ...
    cfg.fiducial.lpa, cfg.fiducial.rpa, cfg.coordsys);

fids_for_mesh = ft_warp_apply(transform_ctf,fiducials.elecpos);
fids_for_mesh = round(fids_for_mesh,6);

% Add this info to .fid field
head_surface_ctf.fid.pos = fids_for_mesh;
head_surface_ctf.fid.label = {'NASION','LPA','RPA'};

%% Export fiducial info to .csv file
% Create table and export as .csv
t = array2table(fids_for_mesh,...
    'RowNames',{'NASION','LPA','RPA'},'VariableNames',{'X','Y','Z'});

writetable(t,'fids_ctf.csv','Delimiter',',','WriteRowNames',true)

t = array2table(fiducials.elecpos,...
    'RowNames',{'NASION','LPA','RPA'},'VariableNames',{'X','Y','Z'});

writetable(t,'fids_native.csv','Delimiter',',','WriteRowNames',true)

%% Export .ply file in bti space
ft_write_headshape([path_to_ply(1:end-4) '_ctf.ply'],head_surface_ctf,'format','ply');

%% Plot figure
try
    figure;
    set(gcf,'Position',[100 100 1000 600]);
    subplot(1,2,1);
    ft_plot_axes(head_surface_ctf);
    ft_plot_mesh(head_surface_ctf);
    view([0,0]);
    subplot(1,2,2);
    ft_plot_axes(head_surface_ctf);
    ft_plot_mesh(head_surface_ctf);
    view([90,0]);
    print(['FIDS'],'-dpng','-r200');
catch
    disp('Could not plot')
end

%% Load in MRI
mri_file    = 'RS.nii';

disp('Reading the MRI file');
mri_orig    = ft_read_mri(mri_file); % in mm, read in mri from DICOM
mri_orig    = ft_convert_units(mri_orig,'mm');
mri_orig.coordsys = 'neuromag';

% Warp FIDS from SPM brain based on nonlinear normalisation
% and transform to BTI space
cfg                         = [];
cfg.nonlinear               = 'yes';
cfg.spmversion              = 'spm12';
mri_normalise               = ft_volumenormalise(cfg,mri_orig);

fids_SPM = [1  85 -41;-83 -20 -65; 83 -20 -65];

fids_SPM_convert = ft_warp_apply(inv(mri_normalise.initial), ...
    ft_warp_apply(mri_normalise.params, fids_SPM, 'sn2individual'));

[transform, coordsys] = ft_headcoordinates(fids_SPM_convert(1,:),...
    fids_SPM_convert(2,:), fids_SPM_convert(3,:), 'ctf');

mri_realigned = ft_transform_geometry(transform,mri_orig);

% check that the MRI is consistent after realignment
ft_determine_coordsys(mri_orig, 'interactive', 'no');
hold on; % add the subsequent objects to the figure
drawnow; % workaround to prevent some MATLAB versions (2012b and 2014b) from crashing
ft_plot_mesh(fids_SPM_convert,'facealpha',0.6);

%
ft_determine_coordsys(mri_realigned, 'interactive', 'no');
hold on; % add the subsequent objects to the figure
drawnow; % workaround to prevent some MATLAB versions (2012b and 2014b) from crashing
ft_plot_mesh(head_surface_ctf,'facealpha',0.6);

%%
cfg = [];
cfg.output    = 'scalp';
cfg.scalpsmooth = 5;
cfg.scalpthreshold = 0.09;
scalp  = ft_volumesegment(cfg, mri_realigned);

%% Create mesh out of scalp surface
cfg = [];
cfg.method = 'isosurface';
cfg.numvertices = 10000;
mesh = ft_prepare_mesh(cfg,scalp);
mesh = ft_convert_units(mesh,'mm');

%% Create Figure for Quality Checking

figure;
ft_plot_mesh(mesh,'facecolor',[238,206,179]./255,'EdgeColor','none','facealpha',0.8); hold on;
camlight; lighting phong; camlight left; camlight right; material dull
hold on; drawnow;
view(90,0) ;drawnow;
title('If this looks weird you might want to adjust the cfg.scalpthreshold value');
print('mesh_quality','-dpng');

%%
numiter = 50;

[R, t, err] = icp(mesh.pos', head_surface_ctf.pos', numiter, ...
    'Minimize', 'plane', 'Extrapolation', true,...
    'WorstRejection', 0.1);

clear plot;
figure; plot([1:1:51]',err,'LineWidth',8);
ylabel('Error'); xlabel('Iteration');
title('Error*Iteration');
set(gca,'FontSize',25);

%% Create transformation matrix
trans_matrix = inv([real(R) real(t);0 0 0 1]);

%% Create figure to assess accuracy of coregistration
mesh_spare = mesh;
mesh_spare.pos = ft_warp_apply(trans_matrix, mesh_spare.pos);
c = datestr(clock); %time and date

figure;
subplot(1,2,1);
ft_plot_mesh(mesh_spare,'facecolor',[238,206,179]./255,'EdgeColor',...
    'none','facealpha',0.8); hold on;
camlight; lighting phong; camlight left; camlight right; material dull; hold on;
ft_plot_headshape(head_surface_ctf,'vertexsize',10); 
title(sprintf('%s', c));
view([90 0]);
subplot(1,2,2);
ft_plot_mesh(mesh_spare,'facecolor',[238,206,179]./255,'EdgeColor',...
    'none','facealpha',0.8); hold on;
camlight; lighting phong; camlight left; camlight right; material dull; hold on;
ft_plot_headshape(head_surface_ctf,'vertexsize',10); 
title(sprintf('Error of ICP fit = %d',err(end)));
view([0 0]);

clear c; print('ICP_quality','-dpng');

%% Apply transform to the MRI
mri_realigned2 = ft_transform_geometry(trans_matrix,mri_realigned);

cfg               = [];
cfg.parameter     = 'anatomy';
cfg.filename      = 'RS_realigned';
cfg.filetype      = 'nifti';
ft_volumewrite(cfg,mri_realigned2);

% check that the MRI is consistent after realignment
ft_determine_coordsys(mri_realigned2, 'interactive', 'no');
hold on; % add the subsequent objects to the figure
drawnow; % workaround to prevent some MATLAB versions (2012b and 2014b) from crashing
ft_plot_mesh(head_surface_ctf,'facealpha',0.6);


%%
figure; ft_plot_mesh(head_surface_ctf);hold on;
ft_plot_mesh(head_surface_ctf.fid.pos,'vertexcolor','b','vertexsize',30);

%% Downsample Headshape
cfg                                 = [];
%cfg.facial_info                     = 'yes';
cfg.downsample_facial_info          = 'yes';
cfg.downsample_facial_info_amount   = 16;
cfg.facial_info_below_x             = 60;
cfg.facial_info_below_z             = 30;

headshape_downsampled       = downsample_headshape_FIL(cfg,head_surface_ctf);
headshape_downsampled       = rmfield(headshape_downsampled,'tri');

figure; ft_plot_headshape(headshape_downsampled);

%% Here we are computing the inverse warp which puts the ipad mesh into
%% the same space as RS.nii

headshape_downsampled1 = ft_transform_geometry(inv(trans_matrix),headshape_downsampled);
headshape_downsampled2 = ft_transform_geometry(inv(transform),headshape_downsampled);

% check that the MRI is consistent after realignment
ft_determine_coordsys(mri_orig, 'interactive', 'no');
hold on; % add the subsequent objects to the figure
drawnow; % workaround to prevent some MATLAB versions (2012b and 2014b) from crashing
ft_plot_mesh(headshape_downsampled2,'facealpha',0.6,'vertexcolor','r');

save headshape_downsampled2 headshape_downsampled2

sens = ft_read_tsv('dummy_positions.tsv')

sens = [sens(:,2) sens(:,3) sens(:,4) ];
sens = table2array(sens)

mri_RS = ft_read_mri

ft_determine_coordsys(mri_orig, 'interactive', 'no');
hold on; % add the subsequent objects to the figure
drawnow; % workaround to prevent some MATLAB versions (2012b and 2014b) from crashing
ft_plot_headshape(headshape_downsampled2)
ft_plot_mesh(sens,'facealpha',0.6,'vertexcolor','g','vertexsize',30);

headshape_downsampled2.fid.pos = round(headshape_downsampled2.fid.pos,6)



