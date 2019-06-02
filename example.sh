#!/bin/bash

########################################################################
#                                                                      #
# This pipeline is only for processing the multicenter diffusion data. #
#                          From Qiqi Tong, CBIST, Zhejiang University. #
#                                                       2019,Hangzhou  #
#                                                                      #
########################################################################

diffname_AP=SMS_AP_S3P2_1_5ISO_00??
diffname_PA=SMS_PA_S3P2_1_5ISO_00??
acqtime=0.05796		#0.69*((146+24)/2-1)/1000		Echo Spacing * (Number of echos - 1)

for subj in 1 2 3;do
{
for inst in LG XY MZ TJ TT ZN ZZ CY HN ZJU ZJU2 ZJU3;do #

DICOMDIR=/hongshan-share/program_brainatlas/data/Multicenter/${inst}TEST00${subj}_${inst}TEST00${subj}
PREPRODIR=/hongshan-share/tongqiqi/BrainAtlas/ScientificData/Proc/${inst}_${subj}
DATADIR=/hongshan-share/tongqiqi/BrainAtlas/ScientificData/UPLOAD_DATA/${inst}_${subj}

bash Preprocessing_diffusion.sh ${DICOMDIR} ${PREPRODIR} ${DATADIR} ${diffname_AP} ${diffname_PA} ${acqtime}

done
}&
done
