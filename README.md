Steps:
1. Install MSVC 2017 or 2019, then run the following command in MATLAB.
```
mex -setup
```
2. Install latest cuda runtime, then run the following command in MATLAB.

```
gpuDevice
```

3. Edit the  **cuda**  path in  _compileTI.m_  file, then run the  _first*.m_  file.
4. Install SIMNIBS and include its MATLAB functions path. 
5. Run  [_headreco_](https://simnibs.github.io/simnibs/build/html/documentation/command_line/headreco.html?highlight=headreco)  and  [_tdcsleadfield_](https://simnibs.github.io/simnibs/build/html/documentation/sim_struct/tdcsleadfield.html#tdcsleadfield-doc)  for the subject. 
    (Or you could run "SIMNIBS_pipeline.m".)
6. Edit the parameters  _TIconfig.m_  file
7. Run  _main.m_  file to optimal TIs parameters.
8. Run  _ex_plot_*.m_  file to plot results.

Note:
1. The plot demo functions are in the folder "Photos".
2. The first time optimization for each subject needs more time to prepare input leadfield for GPU.
3. The 'tet' is nearly 10 times expensive than 'tri' element type.
 
