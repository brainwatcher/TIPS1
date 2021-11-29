function compileTI(src_prefix)
% thrust
src = [src_prefix '.cu'];
path1 =['-I' 'C:\ProgramData\NVIDIA Corporation\CUDA Samples\v10.1\common\inc'];
path2 = ['-I' 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v10.2\include'];
libpath = ['-L' 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v10.2\lib\x64'];
lib1 = ['-l' 'cusparse.lib'];
lib2 = ['-l' 'cublas.lib'];
mexcuda(path1,path2,libpath,lib1,lib2,src);
end
