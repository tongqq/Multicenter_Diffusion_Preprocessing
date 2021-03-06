***
![](https://raw.githubusercontent.com/tongqq/Multicenter_Diffusion_Preprocessing/master/CBIST_logo.png)

### **[CBIST Website](http://cbist.zju.edu.cn/) | Wechat Official Account: CBIST ZJU**
***

<br>

## Multicenter Diffusion Preprocessing Code

### Overview
The code runs on the Linux system (tested sucessfully in CentOS 6.7). The following softwares are required:

* [__FSL 5.0.11 or later__](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation)
* [__Mricron__](https://people.cas.sc.edu/rorden/mricron/install.html)
* [__Freesurfer__](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall) (only for face removal)
* [__MRtrix3__](https://www.mrtrix.org/download/) (optional)
* [__Matlab__](https://www.mathworks.com/products/get-matlab.html) (optional)

The script `example.sh` calls 1) `prep_diffusion.sh` to preprocess the diffusion-weighted images (DWI) described in the reference; 2) `prep_face_removal.sh` to strip the brain skull on both DWI and T1-weighted images. In our local-build high-performance computing cluster, it costs 7~9 hours to process such data for one scan.

<br>

### Feature
`prep_diffusion.sh` is an assembled preprocessing pipeline based on FSL, it mainly uses the `TOPUP` and `EDDY` to correct the head motions as well as the distortions caused by the b0 inhomogeneity and eddy current. It can automatically generate all intermediate parameters and files that needed for the FSL commands. This script is also capable to preprocess other diffusion data, in case the images satisfy the following requirements:

* The b0 images should include opposite phase encoding directions along AP and PA, at least one image along each direction is required.
* The ACQ readout time of the sequence is known. If it is not defined, although the correction output would not be affected, the estimated fieldmap won't be scaled in Hz.

<br>

`prep_face_removal.sh` is an optional process for skull strippig on the T1-weighted images and DWI.

<br>

### Reference
[Tong, Q., He, H., Gong, T., Li, C., Liang, P., Qian, T., ... & Zhong, J. (2019). Reproducibility of multi-shell diffusion tractography on traveling subjects: A multicenter study prospective. Magnetic resonance imaging, 59, 1-9.](https://doi.org/10.1016/j.mri.2019.02.011)

