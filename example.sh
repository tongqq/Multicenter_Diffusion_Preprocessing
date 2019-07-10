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
DICOMDIR = $PWD/Dcm/${inst}TEST00${subj}_${inst}TEST00${subj}
PREPDIR = $PWD/Prep/${inst}_${subj}
DATADIR = $PWD/DATA/${inst}_${subj}

dcmname_T1=MP2RAGE_WIP900*_UNI-DEN_00??
diffname_AP = SMS_AP_S3P2_1_5ISO_00??
diffname_PA = SMS_PA_S3P2_1_5ISO_00??
acqtime = 0.05796		#((146+24)/2-1)*0.69/1000		 (Number of Echos - 1) * Echo Spacing [us]


bash prep_t1.sh ${DICOMDIR} ${PREPDIR} ${DATADIR} ${dcmname_T1}
bash prep_diffusion.sh ${DICOMDIR} ${PREPDIR} ${DATADIR} ${diffname_AP} ${diffname_PA} ${acqtime}

