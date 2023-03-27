  
  % realign both to a common coordinate system
  
  
figure; ft_plot_headshape(headshape_downsampled);
ft_plot_mesh(colin_head);
  
elec2common  = ft_headcoordinates(headshape_downsampled.fid.pos(1,:),...
    headshape_downsampled.fid.pos(2,:), ...
    headshape_downsampled.fid.pos(3,:));

fids_SPM = [1  85 -41;-83 -20 -65; 83 -20 -65];

templ2common = ft_headcoordinates(fids_SPM(1,:),...
    fids_SPM(2,:), ...
    fids_SPM(3,:));

% compute the combined transform
norm         = [];
norm.m       = templ2common \ elec2common;

% % apply the transformation to the fiducials as sanity check
fids_SPM = ft_warp_apply(inv(norm.m),fids_SPM,'homogenous')
 
colin_head_transform = ft_transform_geometry(inv(norm.m),colin_head);

figure; ft_plot_headshape(headshape_downsampled);
ft_plot_mesh(colin_head_transform,'facealpha',0.4);
ft_plot_mesh(fids_SPM,'vertexcolor','g','vertexsize',30);

%%
head_surface = ft_read_headshape('rs_no_interal_faces.ply');

% Add in fids info (not necessary but nice to have)
T = readtable('fids_native.csv');
head_surface.fid.pos = table2array(T(1:3,2:4));
head_surface.fid.label = {'NASION','LPA','RPA'};

figure; ft_plot_mesh(head_surface);
ft_plot_mesh(head_surface.fid.pos,'vertexsize',30,'vertexcolor','g');


%%
fids_SPM = [1  85 -41;-83 -20 -65; 83 -20 -65];
M1 = spm_eeg_inv_rigidreg(head_surface.fid.pos', fids_SPM');


fids_SPM = ft_warp_apply(M1, fids_SPM);

    % constrained affine transform
    %--------------------------------------------------------------------------
    for i = 1:64

        % scale
        %----------------------------------------------------------------------
        M       = pinv(fids_SPM(:))*head_surface.fid.pos(:);
        M       = sparse(1:4,1:4,[M M M 1]);

        fids_SPM = ft_warp_apply(M, fids_SPM);

        M1      = M*M1;

        % and move
        %----------------------------------------------------------------------
        M       = spm_eeg_inv_rigidreg(head_surface.fid.pos', fids_SPM');

        fids_SPM = ft_warp_apply(M, fids_SPM);

        M1      = M*M1;
  
        if (norm(M)-1)< eps
            break;
        end
    end






% % % apply the transformation to the fiducials as sanity check
% fids_SPM2 = ft_warp_apply(M1,fids_SPM)
 
colin_head_transform = ft_transform_geometry(M1,colin_head);

figure; ft_plot_mesh(head_surface,'facealpha',0.3);
ft_plot_mesh(colin_head_transform,'facealpha',0.4);
ft_plot_mesh(fids_SPM,'vertexcolor','g','vertexsize',30);
  
  
  