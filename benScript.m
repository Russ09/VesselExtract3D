
homeDir = '/netshares/mvlprojects6/Registration_Proj/Veerle-Russ_Longitudinal/';
cd(homeDir);

Directory = dir;

for iD = 3:numel(Directory)
    caseFolder = [homeDir Directory(iD).name];
    cd(caseFolder);
    PreConFolder = [caseFolder '/CT-precontrast/'];
    PostConFolder = [caseFolder '/CT-postcontrast/'];
    cd(PreConFolder);
    Dir2 = dir;
    for iF = 3:numel(Dir2)
       name = Dir2(iF).name;
        if(strcmp(name(end-2:end),'nii'))
            PreFileName = Dir2(iF).name;
        end
    end
    
    cd(PostConFolder);
    Dir2 = dir;
    for iF = 3:numel(Dir2)
       name = Dir2(iF).name;
        if(strcmp(name(end-2:end),'nii'))
            PostFileName = Dir2(iF).name;
        end
    end
    cd(caseFolder);
    VesselExtract3D(PreFileName,PreConFolder,PostFileName,PostConFolder);
    
end

