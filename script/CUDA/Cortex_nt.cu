#pragma once
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
/* Using updated (v2) interfaces to cublas */
#include <cuda_runtime.h>
#include <cusparse.h>
#include <cublas_v2.h>
// MATLAB related
#include "mex.h"
#include "gpu/mxGPUArray.h"
#include "mxShowCriticalErrorMessage.c"
#include "Cortexbasic.cuh"
#include "method.cuh"

#define	N_MX	prhs[0]
#define	E0	    prhs[1]
#define	C_MX 	prhs[2]
#define	CU	    prhs[3]
#define	AREA	prhs[4]
#define	K_MX	prhs[5]
#define	METHOD	prhs[6]
#define	VFLAG	prhs[7]
#define	BLOCKSIZE	prhs[8]

#define	RETVAL1	plhs[0]
#define	RETVAL2	plhs[1]

void mexFunction(int nlhs, mxArray * plhs[], int nrhs, const mxArray * prhs[])
{
    // =========================================================================
    // Flag
    // =========================================================================
    bool vflag = *(bool*)mxGetData(VFLAG);
    int blockSize = *(int*)mxGetData(BLOCKSIZE);
    // =========================================================================
    // initial
    // =========================================================================
    mxInitGPU();
    cublasHandle_t cublasHandle = 0;
    cublasStatus_t cublasStatus;
    cublasStatus = cublasCreate(&cublasHandle);
    float time,timePrepare, timeBasic,timeMethod;
    timeBasic = 0;
    timeMethod = 0;
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    const mwSize ndim = 1;
    mwSize dims[ndim];  
    // =========================================================================
    // input N,E0
    // =========================================================================
    cudaEventRecord(start, 0);
    int N = *(int*)mxGetData(N_MX); 
    mxGPUArray const *e0 = mxGPUCreateFromMxArray(E0);
    float *d_e0 = (float*)mxGPUGetDataReadOnly(e0);
    const mwSize *dim0 = mxGetDimensions(E0);
    const int L = dim0[1]; // nt
    const int N128 = dim0[0]; 
    if(vflag)mexPrintf("N: %d  N128: %d  L: %d\n",N,N128,L);
    // =========================================================================
    // input C
    // =========================================================================
    mxGPUArray const *c = mxGPUCreateFromMxArray(C_MX);
    int Nc = mxGetM(C_MX);
    int * d_c = (int*)mxGPUGetDataReadOnly(c);
    if(vflag)mexPrintf("Nc: %d\n",Nc);
    // =========================================================================
    // input CU
    // =========================================================================
    mxGPUArray const *cu = mxGPUCreateFromMxArray(CU);
    float * d_cu = (float*)mxGPUGetDataReadOnly(cu);
    // =========================================================================
    // K
    // =========================================================================
    int K = *(int*)mxGetData(K_MX); 
    // =========================================================================
    // Method,area
    // =========================================================================
    int method = *(int*)mxGetData(METHOD); 
    mxGPUArray const *area = mxGPUCreateFromMxArray(AREA);
    float *d_area = (float*)mxGPUGetDataReadOnly(area);
    int Narea = mxGetM(AREA);
    if(vflag)mexPrintf("Narea: %d\n",Narea);
    if(vflag){
        if(method>0){
                mexPrintf("E is in %d order.\n",method);
                mexPrintf("The target is weighted by area. \n");
        }
        else{
            mexPrintf("E is in 1 order.\n");
            mexPrintf("The target is the MAX of E.\nArea is useless.\n");
        }
    }
    if(vflag){ 
        cudaEventRecord(stop, 0);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&time, start, stop);
        timePrepare = time;
        mexPrintf("prepare time:  %3.3f ms \n",timePrepare);
        mexEvalString("drawnow") ;
    }
    // =========================================================================
    // predefine return b and internal r
    // =========================================================================
    dims[0] = Nc;
    mxGPUArray * b = mxGPUCreateGPUArray(ndim, dims, mxSINGLE_CLASS, mxREAL, MX_GPU_INITIALIZE_VALUES);
    if (b==NULL) mxShowCriticalErrorMessage("mxGPUCreateGPUArray failed");
    float *d_b = (float*)mxGPUGetData(b);  
    int rSize = N128/blockSize*K;
    dims[0] = rSize;
    mxGPUArray * r = mxGPUCreateGPUArray(ndim, dims, mxSINGLE_CLASS, mxREAL, MX_GPU_INITIALIZE_VALUES);
    if (r==NULL) mxShowCriticalErrorMessage("mxGPUCreateGPUArray failed");
    float *d_r = (float*)mxGPUGetData(r);
    if(vflag) mexPrintf("rSize:  %d\n", rSize);
    // =========================================================================
    // process
    // =========================================================================
    int Nloop = Nc/K+1;
    int Nlast = Nc % K;
    int loop100 = ceil((float)Nloop/100);
    if(vflag){
        mexPrintf("Nloop:  %d, K: %d \n", Nloop,K);
        mexEvalString("drawnow") ;
    }
    int Ki = 0;
    for (int i = 0; i<Nloop; i++){
        if(vflag)cudaEventRecord(start, 0);
        if(i<Nloop-1) Ki = K;
        else Ki = Nlast;
        if (Ki == 0) break;
        int Cbase = i*K;
        int N1 = N128 / blockSize;
        int gridSize = N128/blockSize*Ki;
        if(i==0){
            if(vflag){
                mexPrintf("blockSize:  %d, gridSize: %d\n", blockSize,gridSize);
                mexEvalString("drawnow") ;
            }
        }
        if(i==loop100){
            if(vflag){
                mexPrintf("The time consumption of %d loops is about %3.3f ms \n", loop100, timeBasic + timeMethod);
                mexEvalString("drawnow") ;
            } 
        }
        unsigned sharedMemSize = blockSize*sizeof(float);
        BasicCortex_nt<<<gridSize, blockSize,sharedMemSize>>>(Ki, N128, d_e0, Nc, Cbase, d_c, d_cu, d_r, method,d_area);
        // if(i==0)RETVAL2 = mxGPUCreateMxArrayOnCPU(r);
        cudaDeviceSynchronize();   
        if(vflag){ 
            cudaEventRecord(stop, 0);
            cudaEventSynchronize(stop);
            cudaEventElapsedTime(&time, start, stop);
            timeBasic += time;
        }  
        // =====================================================================
        // method
        // ===================================================================== 
        int M = Ki;
        if(vflag)cudaEventRecord(start, 0);
        int blockSize1 = 8;
        int gridSize1 = (M + blockSize1 - 1) / blockSize1;
        if(method==0)
            getMax<<<gridSize1,blockSize1>>>(M, N1, d_r, d_b+i*K);  
        else
            getSum<<<gridSize1,blockSize1>>>(M, N1, d_r, d_b+i*K);
        cudaDeviceSynchronize();
        if(vflag){ 
            cudaEventRecord(stop, 0);
            cudaEventSynchronize(stop);
            cudaEventElapsedTime(&time, start, stop);
            timeMethod += time;
        }  
    }    
    if(method>0){
        float areaSum;
        cublasStatus = cublasSasum(cublasHandle, N, d_area, 1, &areaSum);
        if (cublasStatus!= CUBLAS_STATUS_SUCCESS) mxShowCriticalErrorMessage("cublasSasum in area failed");
        areaSum = 1/areaSum;
        cublasStatus = cublasSscal(cublasHandle, Nc, &areaSum, d_b, 1);
        if (cublasStatus!= CUBLAS_STATUS_SUCCESS) mxShowCriticalErrorMessage("cublasSscal in area scale failed");
    }

    RETVAL1 = mxGPUCreateMxArrayOnCPU(b);
    // =========================================================================
    // destroy
    // =========================================================================
    if(vflag){
        mexPrintf("basic2 time:  %3.3f ms \n",timeBasic);
        mexEvalString("drawnow") ;
        mexPrintf("method time:  %3.3f ms \n",timeMethod);
        mexEvalString("drawnow") ;
        mexPrintf("Other brain part with orientation in GPU ends...\n");
    }
    mxGPUDestroyGPUArray(area);
    mxGPUDestroyGPUArray(r);
    mxGPUDestroyGPUArray(c);
    mxGPUDestroyGPUArray(cu);
    mxGPUDestroyGPUArray(e0);
    mxGPUDestroyGPUArray(b);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    cublasDestroy(cublasHandle);
}
  