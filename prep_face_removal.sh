#!/bin/bash 

########################################################################
#                                                                      #
# This pipeline is only for processing the multicenter diffusion data. #
#                          From Qiqi Tong, CBIST, Zhejiang University. #
#                                                      2019, Hangzhou  #
#                                                                      #
########################################################################

PROJDIR=$1
DICOMDIR=$2
PREPDIR=$3
DATADIR=$4

dcmname_T1=$5

dirtemp=`which mricron`
DCM2NIIDIR=${dirtemp%/*}

echo "===========================Start T1 Preprocessing=========================="

# convert DCM to NIfTI
echo "----------------------------Convert DCM to NIfTI---------------------------"
${DCM2NIIDIR}/dcm2nii -d n -e n -o ${PREPDIR} ${DICOMDIR}/${dcmname_T1} > /dev/null

cd ${PREPDIR}
t1name=`ls -t |head -n1|awk '{print $0}'`
if [ -f ${t1name} ];then
    rm ${t1name:1}
    mv ${t1name:2} T1w_orig.nii.gz
    mv ${t1name} T1w.nii.gz
fi

cd ${PREPDIR}
# Face Removal
echo "--------------------------------Face Removal-------------------------------"
## Freesurfer
mri_deface T1w_orig.nii.gz ${PROJDIR}/talairach_mixed_with_skull.gca ${PROJDIR}/face.gca ${DATADIR}/T1w.nii.gz

# Apply Face Stripping to Diffusion
echo "-----------------------------Apply to Diffusion----------------------------"
bet T1w_orig.nii.gz T1w_brain.nii.gz
flirt -in hifi_b0_brain.nii.gz -ref T1w_brain.nii.gz -dof 12 -omat d2t.mat
convert_xfm -inverse d2t.mat -omat t2d.mat
flirt -in ${DATADIR}/T1w.nii.gz -ref hifi_b0_brain.nii.gz -applyxfm -init t2d.mat -out T1w_diff.nii.gz -interp nearestneighbour
mv ${DATADIR}/diffusion.nii.gz diffusion.nii.gz
fslmaths diffusion.nii.gz -mas T1w_diff.nii.gz ${DATADIR}/diffusion.nii.gz

echo "========================T1 Preprocessing Compeleted========================"

