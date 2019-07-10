#!/bin/bash 

#########################################################################
#																		#
#  This pipeline is only for processing the multicenter diffusion data.	#
#							From Qiqi Tong, CBIST, Zhejiang University.	#
#														2019,Hangzhou	#
#																		#
#########################################################################

DICOMDIR=$1
PREPDIR=$2
DATADIR=$3

dcmname_T1=$4

dirtemp=`which mricron`
DCM2NIIDIR=${dirtemp%/*}


echo "===========================Start T1 Preprocessing=========================="
if [ ! -d ${DATADIR} ];then mkdir ${DATADIR};fi
if [ ! -d ${PREPDIR} ];then mkdir ${PREPDIR};fi

# convert DCM to NIfTI
echo "----------------------------Convert DCM to NIfTI---------------------------"
${DCM2NIIDIR}/dcm2nii -d n -e n -o ${PREPDIR} ${DICOMDIR}/${dcmname_T1} > /dev/null

cd ${PREPDIR}
t1name=`ls -t |head -n1|awk '{print $0}'`
if [ -f ${t1name} ];then
    rm ${t1name:1}
    rm ${t1name:2}
    mv ${t1name} T1.nii.gz
fi

# Skull Stripping
echo "------------------------------Skull Stripping------------------------------"
## Freesurfer
if [ -d ${PREPDIR}/freesurfer ];then rm -rf ${PREPDIR}/freesurfer;fi
recon-all -subject freesurfer -sd ${PREPDIR} -i ${PREPDIR}/T1.nii.gz -autorecon1 -openmp 4
mri_convert freesurfer/mri/brainmask.mgz ${DATADIR}/T1.nii.gz

## FSL
#bet T1.nii.gz ${DATADIR}/T1.nii.gz -f 0.2 -g -0.2

## AFNI
#3dWarp -deoblique -prefix T1.nii.gz T1.nii.gz -overwrite
#3dUnifize -input T1.nii.gz -prefix T1_u.nii.gz -overwrite
#3dSkullStrip -input T1_u.nii.gz -prefix T1_ns.nii.gz -orig_vol -overwrite -push_to_edge
#mv T1_ns.nii.gz ${DATADIR}/T1.nii.gz

echo "========================T1 Preprocessing Compeleted========================"

