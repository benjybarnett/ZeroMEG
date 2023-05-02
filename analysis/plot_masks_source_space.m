%% Plot sources on Anatomical MRI
% Load MRI MNI template
atlas = ft_read_atlas('..\..\..\fieldtrip-master-MVPA\template\atlas\aal\ROI_MNI_V4.nii');
atlas.masks = ones(size(atlas.tissue));
atlas.maskslabel = atlas.tissuelabel;

%Now plot on top of anatomical
cfg               = [];
cfg.method        = 'surface';
cfg.funparameter = 'masks';
cfg.funcolormap = 'jet';
cfg.atlas = atlas;

roi_idxs = find(contains(atlas.tissuelabel,'front','IgnoreCase',true));
cfg.roi = atlas.tissuelabel(roi_idxs);
ft_sourceplot(cfg, atlas);

cfg.roi = {'Calcarine_L'	'Calcarine_R'	'Cuneus_L'	'Cuneus_R'	'Lingual_L'	'Lingual_R'	'Occipital_Sup_L'	'Occipital_Sup_R'	'Occipital_Mid_L'	'Occipital_Mid_R'	'Occipital_Inf_L'	'Occipital_Inf_R'	'Fusiform_L'	'Fusiform_R'};
ft_sourceplot(cfg, atlas);

cfg.roi = {'Parietal_Sup_L'	'Parietal_Sup_R'	'Parietal_Inf_L'	'Parietal_Inf_R' 'SupraMarginal_L'	'SupraMarginal_R'	'Angular_L'	'Angular_R'};
ft_sourceplot(cfg, atlas);

