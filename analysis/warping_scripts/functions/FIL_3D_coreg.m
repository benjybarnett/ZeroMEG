function FIL_3D_coreg(cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIL_3D_coreg: A function for loading in a .ply face mesh and marking the
% location of the true fiducial landmarks versus the 
% acrual location of the MEG coils
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%%%%%%%%%%%
% Inputs:
%%%%%%%%%%%
%
% cfg.dir_name       = folder for saving
% cfg.path_to_ply    = path to the .ply file
% cfg.subject_number = subject number from MEG scan
%
% N.B. If dir_name or path_to_ply not given, the function will open a GUI
% for manual selection of the correct input .ply file
%
%%%%%%%%%%%
% Outputs:
%%%%%%%%%%%
% 'subject_number.csv'
%
%%%%%%%%%%%%%%%%%%%%%%%%
% Example Function Call:
%%%%%%%%%%%%%%%%%%%%%%%%
% cfg                 = [];
% cfg.dir_name        = cd;
% cfg.path_to_ply     = 'test.ply';
% cfg.subject_number  = '0123';
% FIL_3D_coreg(cfg);

%% Fix Toolbar
try %#ok
    if ~verLessThan('matlab','9.5')
        set(groot,'defaultFigureCreateFcn',@(fig,~)addToolbarExplorationButtons(fig));
        set(groot,'defaultAxesCreateFcn',  @(ax,~)set(ax.Toolbar,'Visible','off'));
    end
end

%%
% Get function cfg
dir_name            = ft_getopt(cfg,'dir_name',[]);
path_to_ply         = ft_getopt(cfg,'path_to_ply',[]);
subject_number      = ft_getopt(cfg,'subject_number','XXXX');

% If no dir_name or path_to_obj specified let the user select with GUI
if isempty(dir_name) || isempty(path_to_ply)
    [filename,dir_name] = uigetfile({'*'});
    path_to_ply = [dir_name filename];
end

%% Display
disp('FIL_3D_coreg (v1.0) written by Robert Seymour & George O''Neill, 2021');
ft_warning('Make sure you are using a version of Fieldtrip later than August 2019');

%%
% Cd to the dir_name
cd(dir_name);

%% What should the output file be called?
try
    file_out_name = fullfile(dir_name,[subject_number '.csv']);
catch
    file_out_name = fullfile(dir_name,'XXXX.csv');
end


%% Start of function proper
% Load in data
try
    disp('Loading .ply file. This takes around 10 seconds');
    head_surface = ft_read_headshape(path_to_ply);
catch
   disp('Did you download a version of Fieldtrip later than August 2019?');
end
    
%head_surface.color = head_surface.color./255;
head_surface = ft_convert_units(head_surface,'mm');

% Mark fiducials on headsurface
try
    cfg = [];
    cfg.channel = {'anat_nas','anat_lpa','anat_rpa',...
        'coil_nas','coil_lpa','coil_rpa'};
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
    cfg.channel = {'anat_nas','anat_lpa','anat_rpa',...
        'coil_nas','coil_lpa','coil_rpa'};
    cfg.method = 'headshape';
    fiducials = ft_electrodeplacement_FIL(cfg,head_surface);
end

% Check if 6 points have been marked
if length(fiducials) ~= 6
    warning('Wrong number of points marked. Proceed with caution');
end

% Replace any spaces with underscore
for i = 1:length(fiducials.label)
    fiducials.label{i} = regexprep(fiducials.label{i}, ' ', '_');
end

% Create table and export as .csv
t = table(fiducials.chanpos(:,1),...
    fiducials.chanpos(:,2),...
    fiducials.chanpos(:,3),...
    'RowNames',fiducials.label,'VariableNames',{'X','Y','Z'});

writetable(t,file_out_name,'Delimiter',',','WriteRowNames',true)


end





