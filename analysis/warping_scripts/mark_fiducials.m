%%
% Script to: 1. Mark the fiducial locations on the 3D mesh
%            2. Convert mesh to CTF space (useful for next step)
%            3. Downsample mesh to create 500-800 headshape points,
%            describing the scalp, eyebrows and upper nose
%            4. Output headshape as .pos file
%            5. Output coordinatesystem.json file
%__________________________________________________________________________
% Copyright (C) 2021 Wellcome Trust Centre for Neuroimaging

% Authors:  Robert Seymour      (rob.seymour@ucl.ac.uk) 
%           George O'Neill
%__________________________________________________________________________

%% Repos Required
%  Fieldtrip toolbox and 3Dscanning
addpath(genpath('/Users/rseymoue/Documents/GitHub/3Dscanning'));

%% Paths to files
path_to_data = 'D:\Documents\GB_mesh';

% IMPORTANT: This mesh should be in the same space as your sensor slots!
path_to_ply  = 'gb_edit_hollow.ply';

cd(path_to_data);

%% Load .ply file
head_surface = ft_read_headshape(path_to_ply);
head_surface = ft_convert_units(head_surface,'mm');

% Let user quality check the mesh
figure;ft_plot_mesh(head_surface,'facealpha',0.4);
title({'Make sure this mesh is ';'hollow (no internal surfaces)'});

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


%% Export fiducial info to .csv file
% Create table and export as .csv
t = array2table(fiducials.elecpos,...
    'RowNames',{'NASION','LPA','RPA'},'VariableNames',{'X','Y','Z'});

writetable(t,'fids_native.csv','Delimiter',',','WriteRowNames',true)

% Add this info to .fid field
head_surface.fid.pos = fiducials.elecpos;
head_surface.fid.label = {'NASION','LPA','RPA'};


%% Plot figure
try
    figure;
    set(gcf,'Position',[100 100 1000 600]);
    subplot(1,2,1);
    ft_plot_axes(head_surface);
    ft_plot_headshape(head_surface);
    view([0,0]);
    camlight;
    subplot(1,2,2);
    ft_plot_axes(head_surface);
    ft_plot_headshape(head_surface);
    camlight;
    view([90,0]);
    print('fids_native','-dpng','-r200');
catch
    disp('Could not plot')
end


% %% Write headshape to .pos file (GON code)
% % NOTE: Not recommended. There will usually be many 1000s of 
% %       unnecessary points, including vertices covering the lower face, 
% %       which might confuse Fieldtrip/SPM when performing co-reg.
% 
% try
%     write_pos(fullfile(path_to_data,[path_to_ply(1:end-4) '.pos']),...
%         head_surface);
%     disp('.pos file written out successfully')
% catch
%     disp('ERROR when writing out .pos file');
% end

%% Convert to CTF space & save info
cfg                 = [];
cfg.method          = 'fiducial';
cfg.coordsys        = 'ctf';
cfg.fiducial.nas    = fiducials.elecpos(1,:); %position of NAS
cfg.fiducial.lpa    = fiducials.elecpos(2,:); %position of LPA
cfg.fiducial.rpa    = fiducials.elecpos(3,:); %position of RPA
head_surface_ctf    = ft_meshrealign(cfg,head_surface);

% Save fiducial information in BTI space
transform_ctf = ft_headcoordinates(cfg.fiducial.nas, ...
    cfg.fiducial.lpa, cfg.fiducial.rpa, cfg.coordsys);

fids_for_mesh = ft_warp_apply(transform_ctf,fiducials.elecpos);
fids_for_mesh = round(fids_for_mesh,6);

% Add this info to .fid field
head_surface_ctf.fid.pos = fids_for_mesh;
head_surface_ctf.fid.label = {'NASION','LPA','RPA'};

% Check they are the right way up
figure;
ft_plot_headshape(head_surface_ctf);
view([90 0]); camlight;

%% Export fiducial info to .csv file
% Create table and export as .csv
t = array2table(fids_for_mesh,...
    'RowNames',{'NASION','LPA','RPA'},'VariableNames',{'X','Y','Z'});

writetable(t,'fids_ctf.csv','Delimiter',',','WriteRowNames',true)

%% Export headshape file in bti space
try
    ft_write_headshape([path_to_ply(1:end-4) '_ctf.ply'],...
        head_surface_ctf,'format','ply');
catch
    disp('Could not export headshape');
end

%% Downsample Headshape in CTF space
% Currently downsample_headshape_FIL only works if the mesh is in ctf or
% bti space. Perhaps this could be changed...
%
% NOTE: The cfg.values might need to be changed depending on the size 
%       and density of your mesh. For meshes of kid's heads they 
%       DEFINITLEY need changing

cfg                                 = [];
cfg.facial_info                     = 'yes';
cfg.downsample_facial_info          = 'yes';
cfg.downsample_facial_info_amount   = 13;
cfg.remove_zlim                     = 30;
cfg.facial_info_below_x             = 60;
cfg.facial_info_below_z             = 40;

headshape_downsampled       = downsample_headshape_FIL(cfg,head_surface_ctf);
headshape_downsampled       = rmfield(headshape_downsampled,'tri');


%% Warp headshape back to original coordinate system

headshape_downsampled.pos = ft_warp_apply(inv(transform_ctf),headshape_downsampled.pos);
headshape_downsampled.fid = head_surface.fid;


figure; ft_plot_headshape(headshape_downsampled); hold on;
ft_plot_mesh(head_surface,'facealpha',0.4);
view([90 0]); title('Quality check this downsampled headshape');
camlight;

%% Write downsampled headshape to .pos file (GON code)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% You can rename this file after
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    write_pos(fullfile(path_to_data,[path_to_ply(1:end-4) '.pos']),...
        headshape_downsampled);
    disp('.pos file written out successfully');
catch
    disp('ERROR when writing out .pos file');
end

%% Export to coordinate system.json (TO DO)
json                        = [];
json.MEGCoordinateSystem    = 'Other';
json.MEGCoordinateUnits     = 'mm';
json.MEGCoordinateSystemDescription = 'Fiducial points are in the native world coordinates of a 3D mesh, acquired using Structure io sensor'
json.HeadCoilCoordinates.coil1 = head_surface.fid.pos(1,:);
json.HeadCoilCoordinates.coil2 = head_surface.fid.pos(2,:);
json.HeadCoilCoordinates.coil3 = head_surface.fid.pos(3,:);
json.HeadCoilCoordinateUnits = 'mm';
json.HeadCoilCoordinateSystemDescription = ...
    'Coil1: Nasion; Coil2: LPA; Coil3: RPA. Marked manually on the 3D mesh';
json.AnatomicalLandmarkCoordinateSystem  = 'Other'
json.AnatomicalLandmarkCoordinateUnits   = 'mm'
json.AnatomicalLandmarkCoordinateSystemDescription = ...
    'Not associated with an MRI - sensor positions in the native world coordinates of a 3D mesh';

% Optional depending on whether you have headshape points
json.DigitizedHeadPoints = [path_to_ply(1:end-4) '.pos'];
json.DigitizedHeadPointsCoordinateSystem = 'Other';
json.DigitizedHeadPointsCoordinateSystemDescription = 'Headshape points are in the native world coordinates of a 3D mesh, acquired using Structure io sensor';
json.DigitizedHeadPointsCoordinateUnits = 'mm';

% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write using ft_write_json: you can rename this after
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    ft_write_json(fullfile(path_to_data,[path_to_ply(1:end-4) '.json']),json);
catch
    disp('Could not write json file. Perhaps try a more recent Fieldtrip version');
end





