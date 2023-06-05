%% Plot sources on Anatomical MRI
% Load MRI MNI template
atlas = ft_read_atlas('..\..\..\fieldtrip-master-MVPA\template\atlas\aal\ROI_MNI_V4.nii');
atlas.masks = ones(size(atlas.tissue));
atlas.maskslabel = atlas.tissuelabel;

anat =  ft_read_mri('..\..\..\fieldtrip-master-MVPA/template/anatomy/single_subj_T1_1mm.nii');
anat.coordsys = 'mni';

%Now plot on top of anatomical
cfg               = [];
cfg.method        = 'surface';
cfg.surffile = 'surface_white_right.mat';
%cfg.surfinflated = 'surface_inflated_left.mat';
cfg.funparameter = 'masks';
cfg.funcolormap = 'jet';
cfg.camlight = 'no';
cfg.atlas = atlas;

cfg.roi = {'Cingulum_Ant_L','Cingulum_Ant_R','Rectus_L','Rectus_R','Frontal_Sup_L'	'Frontal_Sup_R'	'Frontal_Sup_Orb_L'	'Frontal_Sup_Orb_R'	'Frontal_Mid_L'	'Frontal_Mid_R'	'Frontal_Mid_Orb_L'	'Frontal_Mid_Orb_R'	'Frontal_Inf_Oper_L'	'Frontal_Inf_Oper_R'	'Frontal_Inf_Tri_L'	'Frontal_Inf_Tri_R'	'Frontal_Inf_Orb_L'	'Frontal_Inf_Orb_R'	'Frontal_Sup_Medial_L'	'Frontal_Sup_Medial_R'	'Frontal_Med_Orb_L'	'Frontal_Med_Orb_R'};
ft_sourceplot(cfg, atlas,anat);
%set non-mask voxels to 0
atlas.masks(find(~ismember(atlas.tissue,find(contains(atlas.tissuelabel,cfg.roi))))) = 0;
disp(sum(atlas.masks,"all"))
disp('here1')
cfg = [];
cfg.filename = 'frontal_mask';
cfg.filetype = 'nifti';
cfg.parameter = 'masks';
ft_sourcewrite(cfg,atlas)

%{
cfg.roi = {'Calcarine_L'	'Calcarine_R'	'Cuneus_L'	'Cuneus_R'	'Lingual_L'	'Lingual_R'	'Occipital_Sup_L'	'Occipital_Sup_R'	'Occipital_Mid_L'	'Occipital_Mid_R'	'Occipital_Inf_L'	'Occipital_Inf_R'	'Fusiform_L'	'Fusiform_R'};
ft_sourceplot(cfg, atlas);
%}

cfg = [];
atlas.masks = ones(size(atlas.tissue));
cfg.atlas = atlas;
cfg.method        = 'surface';
cfg.surffile = 'surface_white_right.mat';
cfg.funparameter = 'masks';
cfg.funcolormap = 'jet';
cfg.camlight = 'no';
cfg.roi = {'Parietal_Sup_L'	'Parietal_Sup_R'	'Parietal_Inf_L'	'Parietal_Inf_R' 'SupraMarginal_L'	'SupraMarginal_R'	'Angular_L'	'Angular_R' 'Precuneus_L' 'Precuneus_R'};
ft_sourceplot(cfg, atlas,anat);
%set non-mask voxels to 0
atlas.masks(find(~ismember(atlas.tissue,find(contains(atlas.tissuelabel,cfg.roi))))) = 0;
disp(sum(atlas.masks,"all"))
disp('here2')
cfg = [];
cfg.filename = 'parietal_mask';
cfg.filetype = 'nifti';
cfg.parameter = 'masks';
ft_sourcewrite(cfg,atlas)

