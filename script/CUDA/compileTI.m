function compileTI(src_prefix)
src = [src_prefix '.cu'];
path1 = ['-I' 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.3\include'];
libpath = ['-L' 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.3\lib\x64'];
lib1 = ['-l' 'cusparse.lib'];
lib2 = ['-l' 'cublas.lib'];
mexcuda(path1,libpath,lib1,lib2,src);
end
