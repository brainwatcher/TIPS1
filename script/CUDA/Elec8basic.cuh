#include "basic2.cuh"
#include "PRmethod.cuh"
__constant__ int  AidxConst[3];
__constant__ int  BidxConst[3];
__constant__ float UConst[8192];
__global__ void BasicElec8(int N, float *e0, int Nc, int basec, int Kc, int* c, int Mu, int Ku, int p ,float * r, float* area)           
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
    float* d_eA3 = e0+N3*(AidxConst[2]-1);
    float* d_eB1 = e0+N3*(BidxConst[0]-1);
    float* d_eB2 = e0+N3*(BidxConst[1]-1);
    float* d_eB3 = e0+N3*(BidxConst[2]-1);

    float* d_eA4 = e0+N3*(*(c+basec+ic)-1);
    float* d_eB4 = e0+N3*(*(c+basec+ic+Nc)-1);

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

    float eA4x = d_eA4[i];
    float eA4y = d_eA4[i+N];
    float eA4z = d_eA4[i+N*2];
    float eB4x = d_eB4[i];
    float eB4y = d_eB4[i+N];
    float eB4z = d_eB4[i+N*2];    
    float ax,ay,az,bx,by,bz;

    for (int j = 0 ; j<Ku; j++){
        ax = UConst[j*Mu]*eA1x + UConst[1+j*Mu]*eA2x + UConst[2+j*Mu]*eA3x + UConst[3+j*Mu]*eA4x;
        ay = UConst[j*Mu]*eA1y + UConst[1+j*Mu]*eA2y + UConst[2+j*Mu]*eA3y + UConst[3+j*Mu]*eA4y;
        az = UConst[j*Mu]*eA1z + UConst[1+j*Mu]*eA2z + UConst[2+j*Mu]*eA3z + UConst[3+j*Mu]*eA4z;
        bx = UConst[4+j*Mu]*eB1x + UConst[5+j*Mu]*eB2x + UConst[6+j*Mu]*eB3x + UConst[7+j*Mu]*eB4x;
        by = UConst[4+j*Mu]*eB1y + UConst[5+j*Mu]*eB2y + UConst[6+j*Mu]*eB3y + UConst[7+j*Mu]*eB4y;
        bz = UConst[4+j*Mu]*eB1z + UConst[5+j*Mu]*eB2z + UConst[6+j*Mu]*eB3z + UConst[7+j*Mu]*eB4z;
        float norma = norm3df(ax,ay,az);
        float normb = norm3df(bx,by,bz);  
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
__global__ void getSum(int N, int M, int Kci, int basec, int Nc, int baseu, float* d_r, float * d_b)
{
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int x = i % Kci;
    int y = i / Kci;
    int offset = N*(x+y*Kci);
    int bx = basec + x;
    int by = baseu + y;
    if(i < M ){
        float tmp = 0;
        for(int ii = 0; ii<N; ii++)
            tmp += *(d_r+offset+ii);
        d_b[bx+by*Nc] = tmp;
    }
}
__global__ void getMax(int N, int M, int Kci, int basec, int Nc, int baseu, float* d_r, float * d_b)
{
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int x = i % Kci;
    int y = i / Kci;
    int offset = N*(x+y*Kci);
    int bx = basec + x;
    int by = baseu + y;
    if(i < M ){
        float tmp = 0;
        float tmp1;
        for(int ii = 0; ii<N; ii++){
            tmp1 = *(d_r+offset+ii);
            if (tmp < tmp1)
                tmp = tmp1;
        }
        d_b[bx+by*Nc] = tmp;
    }
}


        