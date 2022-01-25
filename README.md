TIPS（temporal interference parameter simulation）
Authors: Zhang Wei(weisheep@mail.ustc.edu.cn) and Ma Ru (maru@mail.ustc.edu.cn)

This toolbox aims at temporal interference simulation (TIS) optimization with GPU acceleration.   
It helps experimenter to evaluate the individual TIS stimulation parameters, including electrode position and current intensity.
The evaluation needs the T1 and T2 MRI structural image of the subject to build tetrahedron brain mesh.This step is rely on SIMNIBS pipeline. 
    https://simnibs.github.io/simnibs/build/html/documentation/command_line/headreco.html?highlight=headreco
TIPS is based on MATLAB and CUDA. 
****
Computer recommended configuration
Memory > 8G 
SSD >= 256G (for virtual memory)
Platform: windows 10
GPU: NVIDIA, support CUDA, memory > 4G 
****
Installation steps (on Windows 10):
1. Install MSVC 2017 or 2019, then run the following command in MATLAB.
```
mex -setup
```
2. Install latest cuda runtime, then run the following command in MATLAB.

```
gpuDevice
```
3. Install SIMNIBS and include its MATLAB functions path. 
4. Download this toolbox. 
5. Run _first_AddPath.m_ to add path to MATLAB.
6. Run _first_CompileCUDA.m_ to compile the cuda script into mexw64 file.
7. For each subject, you could follow [_headreco_](https://simnibs.github.io/simnibs/build/html/documentation/command_line/headreco.html?highlight=headreco) to build individual brain mesh. 
    (Or you could run "SIMNIBS_headreco.m".)
8. For each subject, you could follow [_leadfield_](https://simnibs.github.io/simnibs/build/html/documentation/sim_struct/tdcsleadfield.html#tdcsleadfield-doc) to get gray matter middle surface.
    (Or you could run "SIMNIBS_LF_tri.m".)
9. For each subject, you could follow [_leadfield_](https://simnibs.github.io/simnibs/build/html/documentation/sim_struct/tdcsleadfield.html#tdcsleadfield-doc) to get tetrahdron leadfield.
    (Or you could run "SIMNIBS_LF_tet.m".) 
10. Run _TIPSconfig_GUI.mlapp.m_ to set the optimal parameters. (Or you could use _TIPSconfig.m_). The configurations are stored in the "cfg" variable.
11. Run OpenTIPS(cfg) in command line to optimal TIs parameters.
12. Run  _post_plot.m_ file to plot results.
****
Note:
1. Some plot demo functions are in the folder "ex_Figures".
2. The first time optimization for each subject needs more time to prepare input leadfield for GPU.
****
Citation
1. [_SIMNIBS_](https://simnibs.github.io/simnibs/build/html/index.html)
Saturnino, G. B., Siebner, H. R., Thielscher, A., & Madsen, K. H. (2019). Accessibility of cortical regions to focal TES: Dependence on spatial position, safety, and practical constraints. NeuroImage, 203, 116183.
2. [_ACID_](http://www.diffusiontools.com/index.html)
Ruthotto L, Kugel H, Olesch J, Fischer B, Modersitzki J, Burger M, and Wolters C H. Diffeomorphic Susceptibility Artefact Correction of Diffusion-Weighted Magnetic Resonance Images.Physics in Medicine and Biology, 57(18), 5715-5731; 2012, doi: 10.1088/0031-9155/57/18/5715.
3. [_AAL3_](https://www.gin.cnrs.fr/en/tools/aal/)
Automated anatomical labelling atlas 3. Rolls, E. T., Huang, C. C., Lin, C. P., Feng, J., & Joliot, M., Neuroimage, 2020, 206, 116189, doi:10.1016/j.neuroimage.2019.116189
****
Lisence
TIPS is copyrighted © by its authors and licensed under GPL v3.

