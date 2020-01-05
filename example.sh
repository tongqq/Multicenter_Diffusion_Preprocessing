#!/bin/bash

########################################################################
#                                                                      #
# This pipeline is only for processing the multicenter diffusion data. #
#                          From Qiqi Tong, CBIST, Zhejiang University. #
#                                                      2019, Hangzhou  #
#                                                                      #
########################################################################

inst = ZJU
subj = 1
PROJDIR = $PWD
DICOMDIR = $PWD/Dcm/${inst}TEST00${subj}_${inst}TEST00${subj}
PREPDIR = $PWD/Prep/${inst}_${subj}
DATADIR = $PWD/DATA/${inst}_${subj}

dcmname_T1=MP2RAGE_WIP900*_UNI-DEN_00??
diffname_AP = SMS_AP_S3P2_1_5ISO_00??
diffname_PA = SMS_PA_S3P2_1_5ISO_00??
acqtime = 0.050025		#0.345*(146-1)/1000=0.050025		  Echo Spacing * (Number of Echos - 1)  [sec]



bash Prep_diffusion.sh ${PROJDIR} ${DICOMDIR} ${PREPDIR} ${DATADIR} ${diffname_AP} ${diffname_PA} ${acqtime}
bash Prep_face_removal.sh ${PROJDIR} ${DICOMDIR} ${PREPDIR} ${DATADIR} ${dcmname_T1}

