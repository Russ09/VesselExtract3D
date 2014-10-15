function [ImageOut] = FixNiftiDims( fname, folder1 )
%Opens a NIFTI file and corrects the header for use in IRTK



if(nargin<1)
    
    	[fname, folder1] = uigetfile('*.nii', 'Choose NIFTI file');
        Image = load_untouch_nii([folder1, fname]);
        
else
    cd(folder1)
    Image = load_untouch_nii(fname);
end
    

nDims = ndims(Image.img);
Image.hdr.dime.dim(1) = nDims;
save_untouch_nii(Image,[folder1,fname]);

if nargout > 0
    ImageOut = Image;


end

