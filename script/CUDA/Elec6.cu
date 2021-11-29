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
#include "Elec6basic.cuh"
// #include "method.cuh"

#define	N_MX	prhs[0]
#define	E0	    prhs[1]
#define	AIDX	prhs[2]
#define	BIDX	prhs[3]
#define	C_MX	prhs[4]
#define	BETA_MX	prhs[5]
#define	AREA	prhs[6]
#define	METHOD	prhs[7]
#define	K_MX	prhs[8]
#define	VFLAG	prhs[9]
#define	BLOCKSIZE	prhs[10]


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
    cudaError_t cudaStatus;
    float time,timePrepare, timeBasic,timeMethod;
    timeBasic = 0;
    timeMethod = 0;
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    const mwSize ndim = 1;
    mwSize dims[ndim];      
    if(vflag)cudaEventRecord(start, 0);
    // =========================================================================
    // input N,E0
    // =========================================================================
    int N = *(int*)mxGetData(N_MX); 
    mxGPUArray const *e0 = mxGPUCreateFromMxArray(E0);
    float *d_e0 = (float*)mxGPUGetDataReadOnly(e0);
    const mwSize *dim0 = mxGetDimensions(E0);
    const int L = dim0[2];
    const int N128 = dim0[0]; 
    if(vflag)mexPrintf("N: %d  N128: %d  L: %d\n",N,N128,L);
    // =========================================================================
    // Aidx,Bidx
    // =========================================================================
    mxGPUArray const *Aidx = mxGPUCreateFromMxArray(AIDX);
    int *d_Aidx = (int*)mxGPUGetDataReadOnly(Aidx);
    int AidxSize = (int)mxGetNumberOfElements(AIDX);
    cudaStatus = cudaMemcpyToSymbol(AidxConst, d_Aidx, sizeof(int) * AidxSize);
    if (cudaStatus != cudaSuccess) mxShowCriticalErrorMessage("cudaMemcpyToSymbol Aidx failed");

    mxGPUArray const *Bidx = mxGPUCreateFromMxArray(BIDX);
    int *d_Bidx = (int*)mxGPUGetDataReadOnly(Bidx);
    int BidxSize = (int)mxGetNumberOfElements(BIDX);
    cudaStatus = cudaMemcpyToSymbol(BidxConst, d_Bidx, sizeof(int) * BidxSize);
    if (cudaStatus != cudaSuccess) mxShowCriticalErrorMessage("cudaMemcpyToSymbol Bidx failed");
    // =========================================================================
    // input C
    // =========================================================================
    mxGPUArray const *c = mxGPUCreateFromMxArray(C_MX);
    int Nc = mxGetM(C_MX);
    int * d_c = (int*)mxGPUGetDataReadOnly(c);
    if(vflag)mexPrintf("Nc: %d\t",Nc);
    // =========================================================================
    // K
    // =========================================================================
    int K = *(int*)mxGetData(K_MX);  
    // =========================================================================
    // beta
    // =========================================================================
    mxGPUArray const *beta = mxGPUCreateFromMxArray(BETA_MX);
    float* d_beta = (float*)mxGPUGetDataReadOnly(beta);  
    int betaSize = (int)mxGetNumberOfElements(BETA_MX);
    int Nbeta = (int)mxGetM(BETA_MX);
    if(vflag)mexPrintf("Nbeta: %d\n",Nbeta);
    cudaStatus = cudaMemcpyToSymbol(betaConst, d_beta, sizeof(float) * betaSize);
    if (cudaStatus != cudaSuccess) mxShowCriticalErrorMessage("cudaMemcpyToSymbol failed");
    // =========================================================================
    // Method,area
    // =========================================================================
    int method = *(int*)mxGetData(METHOD); 
    mxGPUArray const *area = mxGPUCreateFromMxArray(AREA);
    float *d_area = (float*)mxGPUGetDataReadOnly(area);
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
    // predefine return and internal val
    // =========================================================================
    dims[0] = Nbeta*Nc;
    mxGPUArray * b = mxGPUCreateGPUArray(ndim, dims, mxSINGLE_CLASS, mxREAL, MX_GPU_INITIALIZE_VALUES);
    if (b==NULL) mxShowCriticalErrorMessage("mxGPUCreateGPUArray failed");
    float *d_b = (float*)mxGPUGetData(b);  
    int rSize = N128/blockSize*Nbeta*K;
    // int rSize = N128*Nbeta*K;
    dims[0] = rSize;
    mxGPUArray * r = mxGPUCreateGPUArray(ndim, dims, mxSINGLE_CLASS, mxREAL, MX_GPU_INITIALIZE_VALUES);
    if (r==NULL) mxShowCriticalErrorMessage("mxGPUCreateGPUArray failed");
    float *d_r = (float*)mxGPUGetData(r);
    // =========================================================================
    // loop
    // =========================================================================
    int Nloop = Nc / K+1;
    if(vflag){
        mexPrintf("LoopNum : %d \n", Nloop);
        mexPrintf("Per loop : %d \n", K);
        mexEvalString("drawnow") ;
    }
    int Nlast = Nc % K;
    int Ki = 0;
    for (int i = 0; i<Nloop; i++){
        // int i = 0;
        if(vflag)cudaEventRecord(start, 0);
        if(i<Nloop-1) Ki = K;
        else Ki = Nlast;
        if (Ki == 0) break;
        int N1 = N128 / blockSize;
        int gridSize = N128/blockSize*Ki;
        if(i==0){
            if(vflag){
                cudaEventRecord(start, 0);
                mexPrintf("blockSize:  %d, gridSize: %d \n", blockSize,gridSize);
                mexEvalString("drawnow") ;
            }
        }
        int Cbase = i*K;
        unsigned sharedMemSize = blockSize*sizeof(float);
        BasicMore2AB<<<gridSize, blockSize, sharedMemSize>>>(N128, d_e0, Nc, Cbase, Ki, d_c, Nbeta, method, d_r,d_area);
        cudaDeviceSynchronize();   
        if(vflag){ 
            cudaEventRecord(stop, 0);
            cudaEventSynchronize(stop);
            cudaEventElapsedTime(&time, start, stop);
            timeBasic += time;
        }
        // method
        int M = Ki*Nbeta;
        if(vflag)cudaEventRecord(start, 0); 
        int blockSize1 = 8;
        int gridSize1 = (M + blockSize1 - 1) / blockSize1;
        if(method==0)
            getMax<<<gridSize1,blockSize1>>>(N1, M, Ki, Cbase, Nc, d_r, d_b);  
        else
            getSum<<<gridSize1,blockSize1>>>(N1, M, Ki, Cbase, Nc, d_r, d_b);
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
        cublasStatus = cublasSscal(cublasHandle, Nc*Nbeta , &areaSum, d_b, 1);
        if (cublasStatus!= CUBLAS_STATUS_SUCCESS) mxShowCriticalErrorMessage("cublasSscal in method 3 failed");
    }
    RETVAL1 = mxGPUCreateMxArrayOnCPU(b);
    // =========================================================================
    // destroy
    // =========================================================================
    if(vflag){
        mexPrintf("In all : \n");
        mexPrintf("basic2 time:  %3.3f ms \n",timeBasic);
        mexPrintf("method time:  %3.3f ms \n",timeMethod);
        mexEvalString("drawnow") ;
    }
    mxGPUDestroyGPUArray(area);
    mxGPUDestroyGPUArray(r);
    mxGPUDestroyGPUArray(b);
    mxGPUDestroyGPUArray(c);
    mxGPUDestroyGPUArray(e0);
    mxGPUDestroyGPUArray(beta);
    mxGPUDestroyGPUArray(Aidx);
    mxGPUDestroyGPUArray(Bidx);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    cublasDestroy(cublasHandle);

}
