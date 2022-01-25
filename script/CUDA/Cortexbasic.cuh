#include "basic2.cuh"
#include "PRmethod.cuh"
__global__ void BasicCortex(int Kc, int N, float *e0, int Nc, int Cbase, int* c, float* cu, float * r, int p,float*area)                   
{
    extern __shared__ float rShare[];
    int blockPerN = N / blockDim.x;
    int bid = blockIdx.x;
    int tid = threadIdx.x;
    int N3 = N*3; 
    int ic = bid / blockPerN;
    int i = bid % blockPerN * blockDim.x + threadIdx.x;
    int *idx1 = c+Cbase+ic;
    int *idx2 = c+Cbase+ic+Nc;
    int *idx3 = c+Cbase+ic+Nc*2;
    int *idx4 = c+Cbase+ic+Nc*3;
    float* e1 = e0+N3*(*idx1-1);
    float* e2 = e0+N3*(*idx2-1);
    float* e3 = e0+N3*(*idx3-1);
    float* e4 = e0+N3*(*idx4-1);
    float cua = cu[Cbase+ic];
    float cub = 2-cua;
    
    float ax = (e1[i]-e2[i])*cua;
    float ay = (e1[i+N]-e2[i+N])*cua;
    float az = (e1[i+N*2]-e2[i+N*2])*cua;
    float bx = (e3[i]-e4[i])*cub;
    float by = (e3[i+N]-e4[i+N])*cub;
    float bz = (e3[i+N*2]-e4[i+N*2])*cub;
    float norma = norm3df(ax,ay,az);
    float normb = norm3df(bx,by,bz); 
    float r0= basic2P(ax,ay,az,norma,bx,by,bz,normb,p);
    if(p==0)
        rShare[tid]  = r0;
    else
        rShare[tid]  = r0*area[i];
    __syncthreads();
    if(p==0){
        for(int stride = (blockDim.x/2); stride > 32 ; stride /=2){ 
            if(tid < stride){
                rShare[tid] = fmaxf(rShare[tid],rShare[tid + stride]);
                __syncthreads();
            }
        }
        if(tid < 32) warpReduceMax(rShare,tid);
        if(tid == 0) r[bid] = rShare[0]; 
    }
    else{
        for(int stride = (blockDim.x/2); stride > 32 ; stride /=2){ 
            if(tid < stride){
                rShare[tid] += rShare[tid + stride];
                __syncthreads();
            }
        }
        if(tid < 32) warpReduceSum(rShare,tid);
        if(tid == 0) r[bid] = rShare[0]; 
    }
}

__global__ void BasicCortex_nt(int Kc, int N, float *e0, int Nc, int Cbase, int* c, float* cu, float * r, int p,float*area)                   
{
    extern __shared__ float rShare[];
    int blockPerN = N / blockDim.x;
    int bid = blockIdx.x;
    int tid = threadIdx.x;
    int ic = bid / blockPerN;
    int i = bid % blockPerN * blockDim.x + threadIdx.x;
    int *idx1 = c+Cbase+ic;
    int *idx2 = c+Cbase+ic+Nc;
    int *idx3 = c+Cbase+ic+Nc*2;
    int *idx4 = c+Cbase+ic+Nc*3;
    float* e1 = e0+N*(*idx1-1);
    float* e2 = e0+N*(*idx2-1);
    float* e3 = e0+N*(*idx3-1);
    float* e4 = e0+N*(*idx4-1);
    float cua = cu[Cbase+ic];
    float cub = 2-cua;
    float eA = abs(e1[i]-e2[i])*cua;
    float eB = abs(e3[i]-e4[i])*cub;
    //
    if(p==0||p==1)
        rShare[tid]  = 2*min(eA,eB);
    else
        rShare[tid]  = powf(2*min(eA,eB),(float)p)*area[i];
    // Parallel reduction
    __syncthreads();
    if(p==0){
        for(int stride = (blockDim.x/2); stride > 32 ; stride /=2){ 
            if(tid < stride){
                rShare[tid] = fmaxf(rShare[tid],rShare[tid + stride]);
                __syncthreads();
            }
        }
        if(tid < 32) warpReduceMax(rShare,tid);
        if(tid == 0) r[bid] = rShare[0];
    }
    else{
        for(int stride = (blockDim.x/2); stride > 32 ; stride /=2){ 
            if(tid < stride){
                rShare[tid] += rShare[tid + stride];
                __syncthreads();
            }
        }
        if(tid < 32) warpReduceSum(rShare,tid);
        if(tid == 0) r[bid] = rShare[0]; 
    }
}
