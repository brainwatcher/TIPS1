__constant__ float betaConst[32];
#include "PRmethod.cuh"
__global__ void BasicROI(int N, int Kc, int Nc, float *e0,  int* c, int Cbase, int Nbeta, float * r,int p ,float * area)                   
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

    float eAx = e1[i]-e2[i];
    float eAy = e1[i+N]-e2[i+N];
    float eAz = e1[i+N*2]-e2[i+N*2];
    float eBx = e3[i]-e4[i];
    float eBy = e3[i+N]-e4[i+N];
    float eBz = e3[i+N*2]-e4[i+N*2];
    float normA = norm3df(eAx,eAy,eAz);
    float normB = norm3df(eBx,eBy,eBz); 
    // ensure alpha < pi/2
    float dot_idx = eAx*eBx+eAy*eBy+eAz*eBz;
    if (dot_idx<0)
    {
        eBx = -eBx;
        eBy = -eBy;
        eBz = -eBz;
        dot_idx = -dot_idx;
    }
    // cosalpha
    float cosalpha = dot_idx/(normA*normB);
    // loop for 21 times
    float alpha,beta;
    float r0 ;
    for (int j = 0; j<Nbeta;j++){
        alpha = betaConst[j];
        beta = 2-alpha;
        float ax = alpha*eAx;
        float ay = alpha*eAy;
        float az = alpha*eAz;
        float bx = beta*eBx;
        float by = beta*eBy;
        float bz = beta*eBz;
        float norma = alpha*normA;
        float normb = beta*normB;
        // ensure Ea>Eb 
        if (norma<normb)
        {   
            float tmp;
            tmp = ax; ax = bx; bx = tmp;
            tmp = ay; ay = by; by = tmp;
            tmp = az; az = bz; bz = tmp;
            tmp = norma; norma = normb; normb = tmp;
        }
        if (normb>norma*cosalpha)
        {
            float cx = ax-bx;
            float cy = ay-by;
            float cz = az-bz;
            float crossx = by*cz-bz*cy;
            float crossy = bz*cx-bx*cz;
            float crossz = bx*cy-by*cx;
            float t1 = crossx*crossx+crossy*crossy+crossz*crossz;
            float t2 = cx*cx+cy*cy+cz*cz;
            if (p<2)
                r0 = 2*sqrtf(t1/t2); 
            else if(p==2)
                r0 = 4*t1/t2; 
            else
                r0 = powf(2*sqrtf(t1/t2),(float)p);
        }
        else{
            if(p<2)
                r0 = 2*normb;
            else if(p==2)
                r0 = 4*normb*normb; 
            else
                r0 = powf(2*normb,(float)p);
        }

        if(p==0) rShare[tid] = r0;
        else rShare[tid] = r0*area[i];
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
__global__ void getSum(int N, int M, int Kci, int basec, int Nc, float* d_r, float * d_b)
{
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int x = i % Kci;
    int y = i / Kci;
    int offset = N*(x+y*Kci);
    x = basec + x;
    if(i < M ){
        float tmp = 0;
        for(int ii = 0; ii<N; ii++)
            tmp += *(d_r+offset+ii);
        d_b[x+y*Nc] = tmp;
    }
}
__global__ void getMax(int N, int M, int Kci, int basec, int Nc, float* d_r, float * d_b)
{
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int x = i % Kci;
    int y = i / Kci;
    int offset = N*(x+y*Kci);
    x = basec + x;
    if(i < M ){
        float tmp = 0;
        float tmp1;
        for(int ii = 0; ii<N; ii++){
            tmp1 = *(d_r+offset+ii);
            if (tmp < tmp1)
                tmp = tmp1;
        }
        d_b[x+y*Nc] = tmp;
    }
}

