# Multicenter_Diffusion_Preprocessing

The code runs on the Linux system. The following softwares are required:

* [__FSL 5.0.11__](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation)
* [__Mricron__](https://people.cas.sc.edu/rorden/mricron/install.html)

<br>

The script Preprocessing_all_sub.sh calls Preprocessing_diffusion.sh to preprocess the diffusion-weighted images described in the ref.

The Preprocessing_diffusion.sh is capable to preprocess other diffusion data, in case the images meet the following requirements:

* The b0 images contain opposite phase encoding directions along AP and PA, at least one image along each direction was acquired.
* The ACQ readout time of the sequence is known.

<br>

### Reference:

[Tong, Q., He, H., Gong, T., Li, C., Liang, P., Qian, T., ... & Zhong, J. (2019). Reproducibility of multi-shell diffusion tractography on traveling subjects: A multicenter study prospective. Magnetic resonance imaging, 59, 1-9.](https://doi.org/10.1016/j.mri.2019.02.011)

