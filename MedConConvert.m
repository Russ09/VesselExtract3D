function [] = MedConConvert( nFiles )

disp('Converting raw CT image data into NIFTI format');
close all;

if(isunix)
    SubFolder = '/';
else
    SubFolder = '\';
end

FileName = mfilename();
FolderName = mfilename('fullpath');
FolderName = FolderName(1:end-length(FileName));

addpath(genpath(FolderName));

MedCon = [FolderName 'third_party' SubFolder 'XMedCon' SubFolder 'bin' SubFolder];

if nargin == 0
        nFiles = 1;
end

for iF = 1:nFiles
    [fname{iF}, folder1{iF}] = uigetfile('*.hdr', 'Select Image header to convert');
end

cd(MedCon)

for iF = 1:nFiles
    
    k = strfind(fname{iF},'.');
    name = fname{iF};
    name = name(1:k(1)-1);
    
    String = ['medcon --convert "nifti" -n -f "' folder1{iF} fname{iF} '"'];
    system(String,'-echo');
    
    Files = dir;
    
    for iFiles = 3:numel(Files)
        nameTmp = Files(iFiles).name;
        arg = [name '.nii'];
        k = strfind(nameTmp,arg);
        if numel(k) > 0
            name = nameTmp(1:(k+length(arg)-1));
            break
        end
    end
        
    
    cd(folder1{iF});
    String = ['move "' MedCon name '"'];
    system(String, '-echo');
    
    FixNiftiDims(name,folder1{iF});
    
end

