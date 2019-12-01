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

dcmname_AP=$5
dcmname_PA=$6
acqtime=$7

dirtemp=`which mricron`
DCM2NIIDIR=${dirtemp%/*}
MATLABDIR=/hongshan-share/software-installation-path/matlab2017

echo "=======================Start Diffusion Preprocessing======================="
# Prepare Folders
if [ ! -d ${DATADIR} ];then mkdir ${DATADIR};fi
if [ -d ${PREPDIR} ];then rm -rf ${PREPDIR};fi
mkdir ${PREPDIR}
cd ${PREPDIR}

# Prepare Diffusion Files
echo "--------------------------Prepare Diffusion Files--------------------------"
for pedir in AP PA;do
	# convert dicom to nifti
	eval dcmname=\$dcmname_${pedir}
	${DCM2NIIDIR}/dcm2nii -d n -e n -o ${PREPDIR} ${DICOMDIR}/${dcmname} > /dev/null
	
	# ensure data size along each dimension be even for subsampling in TOPUP
	diffname=`ls -t |head -n1|awk '{print $0}'|cut -d '.' -f1`
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
	mv ${diffname}.bval ${pedir}.bval
	mv ${diffname}.bvec ${pedir}.bvec

echo "--------------------------------Denoise ${pedir}---------------------------------"
	dwidenoise -force ${diffname}.nii.gz ${pedir}.nii.gz -noise noise.mif
	
echo "---------------------------Remove Gibbs-ring ${pedir}----------------------------"
	gunzip ${pedir}.nii.gz
	cd ${PROJDIR}
	${MATLABDIR}/bin/matlab -nodesktop -nosplash -nojvm -r "Prep_gibbsring('${PREPDIR}/${pedir}.nii');quit"
	cd ${PREPDIR}
	gzip ${pedir}.nii
done

# Prepare Files for Processing
echo "---------------------Prepare Files for FSL Processing----------------------"
b0cnt=0
for pedir in AP PA;do
	bval_all=$(cat ${pedir}.bval | tr -s ' ')
	num_diffusion=`${FSLDIR}/bin/fslval ${pedir}.nii.gz dim4`
	eval num_${pedir}=${num_diffusion}
	
	for num in $(seq 1 ${num_diffusion} );do
		bval=`echo ${bval_all} | cut -d ' ' -f ${num}`
		if [ ${bval} -lt 50 ];then
			# extract b0 frames to b0_APPA.nii.gz
			${FSLDIR}/bin/fslroi ${pedir}.nii.gz b0_temp.nii.gz $[${num}-1] 1
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
echo "------------------------TOPUP: Fieldmap Estimation-------------------------"
${FSLDIR}/bin/topup --imain=b0_APPA.nii.gz --datain=acqparam.txt --config=${FSLDIR}/etc/flirtsch/b02b0.cnf --out=topup_results --iout=hifi_b0.nii.gz

cd ${PREPDIR}
# Prepare Files for EDDY
echo "--------------------------Prepare Files for EDDY---------------------------"
${FSLDIR}/bin/bet hifi_b0.nii.gz hifi_b0_brain -m -f 0.3
${FSLDIR}/bin/fslmerge -t APPA.nii.gz AP.nii.gz PA.nii.gz
paste AP.bval PA.bval > APPA.bval
paste AP.bvec PA.bvec > APPA.bvec

# EDDY: Distortion Correction + Motion Correction
echo "--------------EDDY: Distortion Correction + Motion Correction--------------"
${FSLDIR}/bin/eddy_openmp --imain=APPA.nii.gz --mask=hifi_b0_brain_mask.nii.gz --acqp=acqparam.txt --index=index.txt --bvecs=APPA.bvec --bvals=APPA.bval --topup=topup_results --out=corrected_APPA.nii.gz --cnr_maps --repol

# Polishing Files after Processing
echo "----------------------Polishing Files after Processing---------------------"
# seprate corrected_APPA into corrected_AP and corrected_PA
${FSLDIR}/bin/fslroi corrected_APPA.nii.gz corrected_AP.nii.gz 0 ${num_AP}
${FSLDIR}/bin/fslroi corrected_APPA.nii.gz corrected_PA.nii.gz ${num_AP} ${num_PA}
cat corrected_APPA.nii.gz.eddy_rotated_bvecs | while read vector
do
	bvec_temp=`echo ${vector} | tr -s ' ' | awk '{for(i=1;i<='${num_AP}';i++) {printf "%s ",$i}}'`
	echo ${bvec_temp} >> corrected_AP.bvec
	bvec_temp=`echo ${vector} | tr -s ' ' | awk '{for(i='$[${num_AP}+1]';i<='$[${num_AP}+${num_PA}]';i++) {printf "%s ",$i}}'`
	echo ${bvec_temp} >> corrected_PA.bvec
done

if [ ${num_AP} -gt ${num_PA} ];then min=${num_PA};else min=${num_AP};fi
if [ ! -f matrix_AP.txt ];then echo ${min} ${num_AP} >> matrix_AP.txt;fi
if [ ! -f matrix_PA.txt ];then echo ${min} ${num_PA} >> matrix_PA.txt;fi
${FSLDIR}/bin/eddy_combine corrected_AP.nii.gz AP.bval corrected_AP.bvec matrix_AP.txt corrected_PA.nii.gz PA.bval corrected_PA.bvec matrix_PA.txt ${PREPDIR} 0

mv data.nii.gz ${DATADIR}/diffusion.nii.gz
cp corrected_AP.bvec ${DATADIR}/diffusion.bvec
cp AP.bval ${DATADIR}/diffusion.bval
cp hifi_b0_brain_mask.nii.gz ${DATADIR}/diffusion_mask.nii.gz

echo "====================Diffusion Preprocessing Compeleted====================="
