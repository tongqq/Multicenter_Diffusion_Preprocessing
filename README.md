# Multicenter_Diffusion_Preprocessing

The code runs on the Linux system (tested sucessfully in CentOS 6.7). The following softwares are required:

* [__FSL 5.0.11__](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation)
* [__Mricron__](https://people.cas.sc.edu/rorden/mricron/install.html)

<br>

The script example.sh calls prep_diffusion.sh to preprocess the diffusion-weighted images (DWI) described in the reference. In our local-built high-performance computing cluster, it costs 6~8 hours to process such data for one scan.

The prep_diffusion.sh is an assembled preprocessing pipeline based on FSL, it mainly uses the TOPUP and EDDY to correct the head motions as well as the distortions caused by the b0 inhomogeneity and eddy current. It can automatically generate all intermediate parameters and files that needed by the FSL commands. This script is also capable to preprocess other diffusion data, in case the images meet the following requirements:

* The b0 images should include opposite phase encoding directions along AP and PA, at least one image along each direction is required.
* The ACQ readout time of the sequence is known.

<br>

### Reference:

[Tong, Q., He, H., Gong, T., Li, C., Liang, P., Qian, T., ... & Zhong, J. (2019). Reproducibility of multi-shell diffusion tractography on traveling subjects: A multicenter study prospective. Magnetic resonance imaging, 59, 1-9.](https://doi.org/10.1016/j.mri.2019.02.011)

