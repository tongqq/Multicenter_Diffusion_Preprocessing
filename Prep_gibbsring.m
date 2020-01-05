function Prep_gibbsring(funcdir,filename)

addpath(funcdir)
nii=nii_tool('load', filename);
nii.img = unring(nii.img);
nii_tool('save',nii, filename);

