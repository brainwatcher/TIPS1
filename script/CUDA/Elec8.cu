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
#include "Elec8basic.cuh"

#define	N_MX	    prhs[0]
#define	E0	        prhs[1]
#define	AIDX	    prhs[2]
#define	BIDX	    prhs[3]
#define	C_MX	    prhs[4]
#define	KC_MX	    prhs[5]
#define	U_MX	    prhs[6]
#define	KU_MX	    prhs[7]
#define	AREA	    prhs[8]
#define	METHOD	    prhs[9]
#define	VFLAG	    prhs[10]
#define	BLOCKSIZE	prhs[11]


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
    // C, Kc
    // =========================================================================
    mxGPUArray const *c = mxGPUCreateFromMxArray(C_MX);
    int Nc = mxGetM(C_MX);
    int * d_c = (int*)mxGPUGetDataReadOnly(c);
    int Kc = *(int*)mxGetData(KC_MX);  
    if(vflag)mexPrintf("Nc: %d  Kc: %d\n",Nc,Kc);
    // =========================================================================
    // u, Ku
    // =========================================================================
    mxGPUArray const *u = mxGPUCreateFromMxArray(U_MX);
    int Mu = (int)mxGetM(U_MX);
    int Nu = (int)mxGetN(U_MX);
    float* d_u = (float*)mxGPUGetDataReadOnly(u);  
    int Ku = *(int*)mxGetData(KU_MX);  
    if(vflag)mexPrintf("Nu: %d, Mu: %d, Ku: %d\n",Nu,Mu,Ku);
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
    // predefine return b and internal r
    // =========================================================================
    // b
    dims[0] = Nu*Nc;
    mxGPUArray * b = mxGPUCreateGPUArray(ndim, dims, mxSINGLE_CLASS, mxREAL, MX_GPU_INITIALIZE_VALUES);
    if (b==NULL) mxShowCriticalErrorMessage("mxGPUCreateGPUArray failed");
    float *d_b = (float*)mxGPUGetData(b);  
    // r
    int rSize = N128/blockSize*Ku*Kc;
    dims[0] = rSize;
    mxGPUArray * r = mxGPUCreateGPUArray(ndim, dims, mxSINGLE_CLASS, mxREAL, MX_GPU_INITIALIZE_VALUES);
    if (r==NULL) mxShowCriticalErrorMessage("mxGPUCreateGPUArray failed");
    float *d_r = (float*)mxGPUGetData(r);

    // =========================================================================
    // loop
    // =========================================================================
    int Loopc = Nc/Kc+1;
    int Loopu = Nu/Ku+1;
    if(vflag){
        mexPrintf("LoopCNum : %d, LoopUNum: %d \n", Loopc,Loopu);
        mexEvalString("drawnow") ;
    }
    int Lastc = Nc % Kc;
    int Lastu = Nu % Ku;
    int Kci,Kui;
    // =========================================================================
    // iuNum
    // =========================================================================
    int UConstMax = 8192/Mu;
    if(UConstMax<Ku) mxShowCriticalErrorMessage("Not enough constant space for Ku!");
    for (int iu = 0; iu<Loopu; iu++){
        if(iu<Loopu-1) Kui = Ku;
        else Kui = Lastu;
        if (Kui == 0) continue;
        int uConstSize = sizeof(float) *Kui*Mu;
        cudaStatus = cudaMemcpyToSymbol(UConst, d_u+iu*Ku*Mu, uConstSize);
        if (cudaStatus != cudaSuccess) mxShowCriticalErrorMessage("uConst set failed");
        for (int ic = 0; ic<Loopc; ic++){
            // int ic = 0;
            // int iu = 0;
            if(vflag)cudaEventRecord(start, 0);
            // Kci, Kui
            if(ic<Loopc-1) Kci = Kc;
            else Kci = Lastc;
            if (Kci == 0) continue;
            int N1 = N128 / blockSize;
            int gridSize = N128/blockSize*Kci;
             if(ic==0 & iu==0){
                if(vflag){
                    cudaEventRecord(start, 0);
                    mexPrintf("blockSize:  %d, gridSize: %d \n", blockSize,gridSize);
                    mexPrintf("Kci:  %d, Kui: %d \n", Kci,Kui);
                    mexEvalString("drawnow") ;
                }
            }
            int basec = ic*Kc;
            int baseu = iu*Ku;
            unsigned sharedMemSize = blockSize*sizeof(float);
            BasicElec8<<<gridSize, blockSize, sharedMemSize>>>(N128, d_e0, Nc, basec, Kci, d_c, Mu, Kui, method, d_r, d_area);
            cudaDeviceSynchronize(); 
            // if(iu==0)
            //     RETVAL2 = mxGPUCreateMxArrayOnCPU(r);  
            if(vflag){ 
                cudaEventRecord(stop, 0);
                cudaEventSynchronize(stop);
                cudaEventElapsedTime(&time, start, stop);
                timeBasic += time;
            }
            // method
            int M = Kci*Kui;
            if(vflag)cudaEventRecord(start, 0); 
            int blockSize1 = 8;
            int gridSize1 = (M + blockSize1 - 1) / blockSize1;
            
            if(method==0)
                getMax<<<gridSize1,blockSize1>>>(N1, M, Kci, basec, Nc, baseu, d_r, d_b);  
            else
                getSum<<<gridSize1,blockSize1>>>(N1, M, Kci, basec, Nc, baseu, d_r, d_b);
            
                cudaDeviceSynchronize();
            if(vflag){ 
                cudaEventRecord(stop, 0);
                cudaEventSynchronize(stop);
                cudaEventElapsedTime(&time, start, stop);
                timeMethod += time;
            }   
        }
    }
    if(method>0){
        float areaSum;
        cublasStatus = cublasSasum(cublasHandle, N, d_area, 1, &areaSum);
        if (cublasStatus!= CUBLAS_STATUS_SUCCESS) mxShowCriticalErrorMessage("cublasSasum in area failed");
        areaSum = 1/areaSum;
        cublasStatus = cublasSscal(cublasHandle, Nc*Nu , &areaSum, d_b, 1);
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
    mxGPUDestroyGPUArray(u);
    mxGPUDestroyGPUArray(Aidx);
    mxGPUDestroyGPUArray(Bidx);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    cublasDestroy(cublasHandle);

}
