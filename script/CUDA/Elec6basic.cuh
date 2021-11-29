#include "basic2.cuh"
#include "PRmethod.cuh"
__constant__ float betaConst[4096];
__constant__ int  AidxConst[2];
__constant__ int  BidxConst[2];
__global__ void BasicMore2AB(int N, float *e0, int Nc, int Cbase, int Kc, int* c , int Nbeta, int p ,float * r,float*area)           
{
    extern __shared__ float rShare[];
    int blockPerN = N / blockDim.x;
    int bid = blockIdx.x;
    int tid = threadIdx.x;
    int N3 = N*3; 
    int ic = bid / blockPerN;
    int i = bid % blockPerN * blockDim.x + threadIdx.x;
    
    float* d_eA1 = e0+N3*(AidxConst[0]-1);
    float* d_eA2 = e0+N3*(AidxConst[1]-1);
    float* d_eB1 = e0+N3*(BidxConst[0]-1);
    float* d_eB2 = e0+N3*(BidxConst[1]-1);
    float* d_eA3 = e0+N3*(*(c+Cbase+ic)-1);
    float* d_eB3 = e0+N3*(*(c+Cbase+ic+Nc)-1);

    float eA1x = d_eA1[i];
    float eA1y = d_eA1[i+N];
    float eA1z = d_eA1[i+N*2];
    float eB1x = d_eB1[i];
    float eB1y = d_eB1[i+N];
    float eB1z = d_eB1[i+N*2];

    float eA2x = d_eA2[i];
    float eA2y = d_eA2[i+N];
    float eA2z = d_eA2[i+N*2];
    float eB2x = d_eB2[i];
    float eB2y = d_eB2[i+N];
    float eB2z = d_eB2[i+N*2];
      
    float eA3x = d_eA3[i];
    float eA3y = d_eA3[i+N];
    float eA3z = d_eA3[i+N*2];
    float eB3x = d_eB3[i];
    float eB3y = d_eB3[i+N];
    float eB3z = d_eB3[i+N*2];
    float ax,ay,az,bx,by,bz;

    for (int j = 0 ; j<Nbeta; j++){
        ax = betaConst[j]*eA1x + betaConst[j+Nbeta]*eA2x + betaConst[j+2*Nbeta]*eA3x;
        ay = betaConst[j]*eA1y + betaConst[j+Nbeta]*eA2y + betaConst[j+2*Nbeta]*eA3y;
        az = betaConst[j]*eA1z + betaConst[j+Nbeta]*eA2z + betaConst[j+2*Nbeta]*eA3z;
        bx = betaConst[j+3*Nbeta]*eB1x + betaConst[j+4*Nbeta]*eB2x + betaConst[j+5*Nbeta]*eB3x;
        by = betaConst[j+3*Nbeta]*eB1y + betaConst[j+4*Nbeta]*eB2y + betaConst[j+5*Nbeta]*eB3y;
        bz = betaConst[j+3*Nbeta]*eB1z + betaConst[j+4*Nbeta]*eB2z + betaConst[j+5*Nbeta]*eB3z;
        float norma = sqrtf(ax*ax+ay*ay+az*az);
        float normb = sqrtf(bx*bx+by*by+bz*bz);  
        // r[i + j*blockDim.x*gridDim.x] = basic2P(ax,ay,az,norma,bx,by,bz,normb,p);
        if(p==0)
            rShare[tid] = basic2P(ax,ay,az,norma,bx,by,bz,normb,p);
        else
            rShare[tid] = basic2P(ax,ay,az,norma,bx,by,bz,normb,p)*area[i];
        __syncthreads();
        if(p==0){
            for(int stride = (blockDim.x/2); stride > 32 ; stride /=2){ 
                if(tid < stride){
                    rShare[tid] = fmaxf(rShare[tid],rShare[tid + stride]);
                    __syncthreads();
                }
            }
            if(tid < 32) warpReduceMax(rShare,tid);
            if(tid == 0) r[bid+blockPerN*Kc*j] = rShare[0]; 
        }
        else{
            for(int stride = (blockDim.x/2); stride > 32 ; stride /=2){ 
                if(tid < stride){
                    rShare[tid] += rShare[tid + stride];
                    __syncthreads();
                }
            }
            if(tid < 32) warpReduceSum(rShare,tid);
            if(tid == 0) r[bid+blockPerN*Kc*j] = rShare[0]; 
        }
    }
}
__global__ void getSum(int N, int M, int Kc, int Cbase, int Nc, float* d_r, float * d_b)
{
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int bx = Cbase + i % Kc;
    int by = i / Kc;
    if(i < M ){
        float tmp = 0;
        for(int ii = 0; ii<N; ii++)
            tmp += *(d_r+N*i+ii);
        d_b[bx+by*Nc] = tmp;
    }
}
__global__ void getMax(int N, int M, int Kc, int Cbase, int Nc, float* d_r, float * d_b)
{
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int bx = Cbase + i % Kc;
    int by = i / Kc;
    if(i < M ){
        float tmp = 0;
        float tmp1;
        for(int ii = 0; ii<N; ii++){
            tmp1 = *(d_r+N*i+ii);
            if (tmp < tmp1)
                tmp = tmp1;
        }
        d_b[bx+by*Nc] = tmp;
    }
}


        