%%
% Very rough script to try and automate fid marking
%__________________________________________________________________________
% Copyright (C) 2021 Wellcome Trust Centre for Neuroimaging

% Authors:  Robert Seymour      (rob.seymour@ucl.ac.uk) 
%__________________________________________________________________________

%%
path_to_data = '/Users/rseymoue/Downloads/OneDrive_1_23-06-2021';
path_to_ply  = 'export123.ply';

cd(path_to_data);

%% Load .ply file
head_surface = ft_read_headshape(path_to_ply);

figure; ft_plot_mesh(head_surface);

%%
[NAS,angulo] = eeg_B_viola_jones(head_surface, cd);

detector = eeg_C_buildDetector();

close all
figure;
ft_plot_mesh(head_surface);
view(90,0);
imagen = getframe(gcf);
img = imagen.cdata;

figure; imshow(img);

[bbox bbimg faces bbfaces ] = eeg_D_detectFaceParts(detector,img,2);% Recognize the face parts...!!!

IFaces = insertObjectAnnotation(bbimg,'rectangle',bbox,'Face');   
figure
imshow(img)

[a b c] = size(img);

I = bbox(:,5:8);
D = bbox(:,9:12);
N = bbox(:,17:20); 
NAS = [((I(2)+D(2))/2+(I(4)+D(4))/4) , ((N(1)+N(3)/2)+(D(1)+I(1)+I(3))/2)/2 ];
NAS=round(NAS);
bbimg(NAS(1),NAS(2),:)=255;
close all;
imshow(bbimg);

cfg = [];
cfg.method = 'headshape';
fiducials = ft_electrodeplacement_FIL(cfg,head_surface);
ddd = select3d([NAS(1) NAS(2)]);


figure;
ft_plot_mesh(head_surface);
view(90,0);

xyz = eeg_ft_select_point3d_NAS(head_surface,'nearest', false, 'multiple', true, 'marker', '*');% ***********************************

    NAS3d = eeg_ft_electrodeplacement_NAS(cfg, head_surface); 

    
    