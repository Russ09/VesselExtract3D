function [  ] = VesselExtract3D( PreContrastName, PreContrastFolder, PostContrastName, PostContrastFolder )
%Performs vessel extraction on a 3D volume using a frangi filter technique
%and performing non-rigid registration using IRTK.

close all;

if(isunix)
    SubFolder = '/';
else
    SubFolder = '\';
end

FileName = mfilename();
FolderName = mfilename('fullpath');
FolderName = FolderName(1:end-length(FileName));

addpath([FolderName SubFolder 'third_party' SubFolder 'NIFTI_20130306']);
addpath([FolderName SubFolder 'third_party' SubFolder 'frangi_filter']);
addpath([FolderName SubFolder '1_libs']);

addpath(genpath(FolderName));

%Forces the recalculation of all stages
bRecalculate = 0;




disp('Loading...')

FolderName = [SubFolder 'VesselSegmentation' SubFolder];
newFolder = [cd FolderName];

if (nargin < 4)
    [fname1, folder1] = uigetfile('*.nii', 'Open Precontrast image');
    PreContrast = load_untouch_nii([folder1, fname1]);

    [fname2, folder2] = uigetfile([folder1, '*.nii'], 'Open Postcontrast image');
    PostContrast = load_untouch_nii([folder2, fname2]);
else
    fname1 = PreContrastName;
    folder1 = PreContrastFolder;
    fname2 = PostContrastName;
    folder2 = PostContrastFolder;
    PreContrast = load_untouch_nii([folder1, fname1]);
    PostContrast = load_untouch_nii([folder2, fname2]);
end

PreContrast = FixNiftiDims(fname1,folder1);
PostContrast = FixNiftiDims(fname2,folder2);

disp('Pre and Post-contrast images loaded successfully');

folder2 = [cd,FolderName]

if (~exist(newFolder,'dir'))
    mkdir(newFolder);
end

cd(newFolder);

PostImage = PostContrast.img;
PreImage = PreContrast.img;


% -------------------STAGE 1 - CONTRAST ADJUST-----------------------------
% Adjusted contrast difference image
% -------------------------------------------------------------------------
%
% Script to scale the precontrast image using a histogram peak 
% finding approach. This approach assumes that the contrast only 
% makes a small contribution to the overall histogram shape. 
%
% Usage:
% Select the Pre-contrast and post-contrast images using the GUI widget. 
%
% Output:
% A corrected precontrast image and a difference image will be saved in the
% current folder
%
% Author: Benjamin Irving (stuff@birving.com)
% 20140702



if(~exist([folder2,'PreContrast_adjusted.nii'],'file') || bRecalculate)
    
    
    if(isa(PostImage,'uint8'))
        bIsInt = 1;
    else
        bIsInt = 0;
    end
    
        PostImage = single(PostImage);
        PreImage = single(PreImage);

    
    if( isa(PostImage,'uint8'))
        
        disp('Normalised image detected, fitting histograms to compensate for normalisation');
        
        [max_pre, Nfilt_pre, N_pre, X_pre] = find_image_key_greyscale(PreImage);
        [max_post, Nfilt_post, N_post, X_post] = find_image_key_greyscale(PostImage);

        figure(1);
        bar(X_pre, N_pre, 'b', 'EdgeColor', 'none')
        hold on;
        bar(X_post, N_post, 'r', 'EdgeColor', 'none')
        hold off;
        legend({'pre', 'post'})
        title('Original histograms');


        figure(2);
        bar(X_pre, Nfilt_pre, 'b', 'EdgeColor', 'none')
        hold on;
        bar(X_post, Nfilt_post, 'r', 'EdgeColor', 'none')
        hold off;
        legend({'pre', 'post'})
        title('Smoothed histograms');


        % Find the linear regression of the scaling function
        linreg = polyfit(max_pre(:,1), max_post(:,1), 1);

        % Scale the histogram
        X_pre_scale = X_pre * linreg(1) + linreg(2);

        % Plot the final histogram
        figure(3);
        bar(X_pre_scale, Nfilt_pre, 'b', 'EdgeColor', 'none')
        hold on;
        bar(X_post, Nfilt_post, 'r', 'EdgeColor', 'none')
        hold off;
        legend({'pre', 'post'})
        title('Final histograms');


        % Scale the precontrast images
        pre_scale = PreImage *linreg(1) + linreg(2);

        % Difference image
        diff = (PostImage - pre_scale);
        diff = diff .* (diff>0);
        
    else
        
        diff = PostImage - PreImage;
        diff = diff.*(diff>0);

    end

    figure;
    imagesc(diff(:,:,70));
    colormap('gray')
    
    disp('Computing difference image');
    
    diff1 = PreContrast;
    diff1.hdr.dime.datatype = 4;
    diff1.hdr.dime.bitpix = 16;
    diff1.img = diff;
    save_untouch_nii(diff1, [folder2, 'Difference_image.nii'])

    % Save the scaled precontrast image
    
    
    pre1b = PreContrast;
    if(bIsInt)
        pre1b.img = uint8(pre_scale);
    else
        pre1b.img = PreImage;
        pre1b.hdr.dime.dim(1) = 3;
    end
    
    save_untouch_nii(pre1b, [folder2, 'PreContrast_adjusted.nii'])
    save_untouch_nii(PostContrast,[folder2,'PostContrast.nii']);
    clear pre1b PreImage PostImage
    clear PostContrast PreContrast

    disp('Saved Precontrast_adjusted and difference_image')

end

%-------------STAGE 2 - NON-RIGID REGISTRATION IN IRTK --------------------
%   Perform IRTK non-rigid registration between pre/postcontrast
%   Russell Bates
%--------------------------------------------------------------------------
%   Edit function WriteParamsText() to customize the IRTK parameters given
%   for registration. Matlab will then call IRTK from the command line to
%   perform a non-rigid registration as specified in nregparams.txt and
%   then apply this transformation to the PreContrast image saving it as
%   pre_adj_reg.nii
%
%   IRTK must be added to the system path.


if(~exist([folder2,'pre_adj_reg.nii'],'file') || bRecalculate)

    if(~exist([folder2,'nregparams.txt'],'file'))
        disp('Preparing IRTK nreg parameters, writing file nregparams.txt');
        WriteParamsTxt()
    end

    system(['cd ' folder2]);
    %-parin nregparams.txt
    disp('Performing IRTK registration to correct for non-rigid deformations between Pre and Post-contrast')
    timer1 = tic
    t1 = system('nreg PostContrast.nii PreContrast_adjusted.nii -dofout nreg-b-a2.dof -parout par.txt')
    RegistrationTime = toc(timer1);
    
    disp('Applying transformation to Precontrast image')
    t2 = system('transformation Precontrast_adjusted.nii pre_adj_reg.nii -dofin nreg-b-a2.dof -target PostContrast.nii')
    
    
    
    if(t1)
        disp('IRTK Registration failed');
    end
    
    if(t2)
        disp('IRTK transformation failed');
    end
        
end

FixNiftiDims('pre_adj_reg.nii',folder2)

% ------------------- STAGE 3 - DIFFERANCE IMAGES -------------------------
% Difference between CT scans
% Benjamin Irving 20140808
%--------------------------------------------------------------------------
%   Calculates a subtraction image between the aligned pre/post contrast
%   images. Discards negative differences as we are looking for enhanced
%   vessels.

if(~exist([folder2,'Difference_image_reg.nii'],'file') || bRecalculate)

    close all;

    disp('Loading...')

    pre1 = load_untouch_nii('pre_adj_reg.nii');
    post1 = load_untouch_nii('PostContrast.nii');
    
    post = post1.img;

    pre = pre1.img;

    post = single(post);
    pre = single(pre);


    % Difference image
    diff = post - pre;

    % only interested in positive differences
    diff = diff .* (diff>0);

    figure;
    imagesc(diff(:,:,70));
    colormap('gray')

    diff1 = post1;
    diff1.hdr.dime.datatype = 4;
    diff1.hdr.dime.bitpix = 16;
    diff1.img = diff;
    save_untouch_nii(diff1, [folder2, 'Difference_image_reg.nii']);
    clear pre1 post1 diff1 diff pre post

end


% -----------------STAGE 4 - FRANGI FILTER --------------------------------
% Frangi filter and small object removal
% Benjamin Irving 20140808
%--------------------------------------------------------------------------
% Uses an implementation of Frangi Filtering (http://www.mathworks.co.uk/
% matlabcentral/fileexchange/24409-hessian-based-frangi-vesselness-filter/
% content/FrangiFilter3D.m     Dirk-Jan Kroon) to extract vessels from the
% difference image


im1 = load_untouch_nii('Difference_image_reg.nii');

V=im1.img;
V=V+min(V(:));
disp('Applying Frangi Filter to difference image');

% Frangi Filter the stent volume
clear options;
options.BlackWhite=false;
options.FrangiScaleRange=[1 6];
options.FrangiScaleRatio=1;
options.FrangiBeta=0.7;
timer2 = tic;
Vfiltered=FrangiFilter3D(V,options);
FrangiTime = toc(timer2);

disp('Frangi Filter completed, applying threshold');

im2=im1;
im2.img=Vfiltered./max(Vfiltered(:));

im2.img=im2.img*65000;
%im2.hdr.dime.bitpix=32;
%im2.hdr.dime.datatype=16;

save_untouch_nii(im2, [folder2 'frangifiltered.nii']);

pp = 0.015; %0.015 (G02M01)
norm1 = (Vfiltered - min(Vfiltered(:)))./max(Vfiltered(:)- min(Vfiltered(:)));

img_thresh = norm1>pp;


%  Removal of small objects (<100 voxels)
[L, N] = bwlabeln(img_thresh);
img_thresh2 = zeros(size(img_thresh));

for ii =1:N
    disp(ii)
    cc = sum(sum(sum((L==ii))));
    
    if cc>100
        img_thresh2 = img_thresh2 | (L==ii);
    end
end

im2.img=uint8(img_thresh2);
im2.hdr.dime.datatype = 4;
im2.hdr.dime.bitpix = 16;
save_untouch_nii(im2, [folder2 'frangifilteredthresh.nii']);
save('Times.mat','RegistrationTime','FrangiTime');
end

