# Multicenter_Diffusion_Preprocessing

The code runs on the Linux system. The following softwares are required:

* [FSL 5.0.11][FSL]
* [Mricron][Mricron]

The script Preprocessing_all_sub.sh calls Preprocessing_diffusion.sh to preprocess the diffusion-weighted images described in the ref.

The Preprocessing_diffusion.sh is capable to preprocess other diffusion data, in case the images meet the following requirements:

* The sequence contains opposite phase encoding directions along AP and PA, at least one image along each direction was acquired.
* The ACQ readout time of the sequence is known.



Reference:

Tong, Q., He, H., Gong, T., Li, C., Liang, P., Qian, T., ... & Zhong, J. (2019). Reproducibility of multi-shell diffusion tractography on traveling subjects: A multicenter study prospective. Magnetic resonance imaging, 59, 1-9.


<!-- References -->
[FSL]: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation
[Mricron]: https://people.cas.sc.edu/rorden/mricron/install.html
