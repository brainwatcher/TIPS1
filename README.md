Steps:
1. Install MSVC 2017 or 2019, then run the following command in MATLAB.
```
mex -setup
```
2. Install latest cuda runtime, then run the following command in MATLAB.

```
gpuDevice
```

3. Edit the  **cuda**  path in "compileTI.m" file, then run the "first_*.m" file.
4. Install SIMNIBS and include its MATLAB functions path. 
5. Run  _headreco_  and  _tdcsleadfield_  for the subject.
2. Run "main.m" file to optimal TIs parameters.

Note:
1. The plot demo functions are in the folder "Photos".
2. The first time optimization for each subject needs more time to prepare input leadfield for GPU.
3. The 'tet' is nearly 10 times expensive than 'tri' element type.
 
