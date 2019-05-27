#!/bin/bash

########################################################################
#                                                         	 		   #
# This pipeline is only for processing the multicenter diffusion data. #
#						   From Qiqi Tong, CBIST, Zhejiang University. #
#														2019,Hangzhou  #
#                                                         	 		   #
########################################################################

DICOMDIR=$1
PREPRODIR=$2
DATADIR=$3

diffname_AP=$4
diffname_PA=$5
acqtime=$6

DCM2NIIDIR=/share/app/imaging/mricron

echo "==============Start Preprocessing=============="
#Prepare Folders
if [ -d ${PREPRODIR} ]
then
    rm -rf ${PREPRODIR}
fi
    mkdir ${PREPRODIR}
cd ${PREPRODIR}

# Prepare Diffusion Files
echo "--------------Prepare Diffusion Files--------------"
for pedir in AP PA;do
	# convert dicom to nifti
	eval dcmname=\$diffname_${pedir}
	${DCM2NIIDIR}/dcm2nii -d n -e n -o ${PREPRODIR} ${DICOMDIR}/${dcmname}

	# insure data sizes along x,y,z dimensions be even for subsampling in TOPUP
	diffname=`ls -t |head -n1|awk '{print $0}'|cut -d "." -f1`
	xsize=`${FSLDIR}/bin/fslval ${diffname}.nii.gz dim1`
	ysize=`${FSLDIR}/bin/fslval ${diffname}.nii.gz dim2`
	zsize=`${FSLDIR}/bin/fslval ${diffname}.nii.gz dim3`
	if [ $[${xsize} % 2] -eq 1 ];then
		${FSLDIR}/bin/fslroi ${diffname}.nii.gz ${diffname}.nii.gz 0 $[${xsize}-1] 0 -1 0 -1 0 -1
	fi
	if [ $[${ysize} % 2] -eq 1 ];then
		${FSLDIR}/bin/fslroi ${diffname}.nii.gz ${diffname}.nii.gz 0 -1 0 $[${ysize}-1] 0 -1 0 -1
	fi
	if [ $[${zsize} % 2] -eq 1 ];then
		${FSLDIR}/bin/fslroi ${diffname}.nii.gz ${diffname}.nii.gz 0 -1 0 -1 0 $[${zsize}-1] 0 -1
	fi
	
	# rename filename
	mv ${diffname}.nii.gz ${pedir}.nii.gz
	mv ${diffname}.bval ${pedir}.bval
	mv ${diffname}.bvec ${pedir}.bvec
done


# Prepare Files for Processing
echo "--------------Prepare Files for Processing--------------"
b0cnt=0
for pedir in AP PA;do
	bval_all=$(cat ${pedir}.bval | tr -s ' ')
	num_diffusion=`${FSLDIR}/bin/fslval ${pedir}.nii.gz dim4`
	eval num_${pedir}=${num_diffusion}
	for num in $(seq 0 $[${num_diffusion} - 1]);do
		bval=`echo ${bval_all} | cut -d ' ' -f $[${num}+1]`
		if [ ${bval} -lt 50 ];then
			# extract b0 frames to b0_APPA.nii.gz
			${FSLDIR}/bin/fslroi AP.nii.gz b0_temp.nii.gz ${num} 1
			if [ ! -f b0_APPA.nii.gz ];then
				mv b0_temp.nii.gz b0_APPA.nii.gz
			else
				${FSLDIR}/bin/fslmerge -t b0_APPA.nii.gz b0_APPA.nii.gz b0_temp.nii.gz
				rm b0_temp.nii.gz
			fi
			# make acqparam.txt for all b0 frames
			if [ "${pedir}" == "AP" ];then
				pedir_index=-1
			else
				pedir_index=1
			fi
			echo 0 ${pedir_index} 0 ${acqtime} >> acqparam.txt
			b0cnt=$[${b0cnt}+1]
		fi
		# make index.txt for all frames
		echo ${b0cnt} >> index.txt
	done
done

# TOPUP: Fieldmap Estimation
echo "--------------TOPUP: Fieldmap Estimation--------------"
${FSLDIR}/bin/topup --imain=b0_APPA.nii.gz --datain=acqparam.txt --config=${FSLDIR}/etc/flirtsch/b02b0.cnf --out=topup_results --iout=hifi_b0.nii.gz

# Prepare Files for EDDY
echo "--------------Prepare Files for EDDY--------------"
${FSLDIR}/bin/bet hifi_b0.nii.gz hifi_b0_brain -m
${FSLDIR}/bin/fslmerge -t APPA.nii.gz AP.nii.gz PA.nii.gz
paste AP.bval PA.bval > APPA.bvals
paste AP.bvec PA.bvec > APPA.bvecs

# EDDY: Distortion Correction + Motion Correction
echo "--------------EDDY: Distortion Correction + Motion Correction--------------"
${FSLDIR}/bin/eddy_openmp --imain=APPA.nii.gz --mask=hifi_b0_brain_mask.nii.gz --acqp=acqparam.txt --index=index.txt --bvecs=APPA.bvecs --bvals=APPA.bvals --topup=topup_results --out=corrected_APPA.nii.gz

# Polishing Files after Processing
echo "--------------Polishing Files after Processing--------------"
# seprate corrected_APPA into corrected_AP and corrected_PA
${FSLDIR}/bin/fslroi corrected_APPA.nii.gz corrected_AP.nii.gz 0 ${num_ap}
${FSLDIR}/bin/fslroi corrected_APPA.nii.gz corrected_PA.nii.gz ${num_ap} ${num_pa}
cat corrected_APPA.nii.gz.eddy_rotated_bvecs | while read vector
do
	bvec_temp=`echo ${vector} | awk '{for(i=1;i<='${num_ap}';i++) {printf "%s ",$i;i++}}'`
	echo ${bvec_temp} >> corrected_AP.bvec
	bvec_temp=`echo ${vector} | awk '{for(i='$[${num_ap}+1]';i<='$[${num_ap}+${num_pa}]';i++) {printf "%s ",$i;i++}}'`
	echo ${bvec_temp} >> corrected_PA.bvec
done

# combine corrected_AP and corrected_PA to the final files: diffusion.nii.gz, diffusion.bval, diffusion.bvec
if [ ${num_ap} -gt ${num_pa} ];then
    min=${num_pa}
else
    min=${num_ap}
fi
frame_ap=(${min} ${num_ap})
frame_pa=(${min} ${num_pa})
${FSLDIR}/bin/eddy_combine corrected_AP.nii.gz AP.bval corrected_AP.bvec ${frame_ap} corrected_PA.nii.gz PA.bval corrected_PA.bvec ${frame_pa} ${DATADIR} 0
cp corrected_AP.bvec ${DATADIR}/diffusion.bvec
cp AP.bval ${DATADIR}/diffusion.bval

echo "==============Preprocessing Compeleted=============="

