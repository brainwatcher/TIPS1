__device__ float basic2P(float ax,float ay,float az,float norma, float bx,float by,float bz,float normb,int p)
{
    float r0;
    // ensure alpha < pi/2
    float dot_idx = ax*bx+ay*by+az*bz;
    if (dot_idx<0){
        bx = -bx;
        by = -by;
        bz = -bz;
        dot_idx  = -dot_idx;
    }
    // cosalpha
    float cosalpha = dot_idx/(norma*normb);
    // ensure Ea>Eb 
    if (norma<normb){   
        float tmp;
        tmp = ax; ax = bx; bx = tmp;
        tmp = ay; ay = by; by = tmp;
        tmp = az; az = bz; bz = tmp;
        tmp = norma; norma = normb; normb = tmp;
    }
    if (normb>norma*cosalpha){
        float cx = ax-bx;
        float cy = ay-by;
        float cz = az-bz;
        float crossx = by*cz-bz*cy;
        float crossy = bz*cx-bx*cz;
        float crossz = bx*cy-by*cx;
        float t1 = crossx*crossx+crossy*crossy+crossz*crossz;
        float t2 = cx*cx+cy*cy+cz*cz;
        if(p==0) r0 = 2*sqrtf(t1/t2);
        else if(p==1) r0 = 2*sqrtf(t1/t2);
        else if(p==2) r0 = 4*t1/t2; 
        else r0 = powf(2*sqrtf(t1/t2),(float)p);
    }
    else{
        if(p==0) r0 = 2*normb;
        else r0 = powf(2*normb,(float)p);
    }  
    return r0;
}
__device__ float basic2(float ax,float ay,float az,float norma, float bx,float by,float bz,float normb)
{
    float r0;
    // ensure alpha < pi/2
    float dot_idx = ax*bx+ay*by+az*bz;
    if (dot_idx<0){
        bx = -bx;
        by = -by;
        bz = -bz;
        dot_idx  = -dot_idx;
    }
    // cosalpha
    float cosalpha = dot_idx/(norma*normb);
    // ensure Ea>Eb 
    if (norma<normb){   
        float tmp;
        tmp = ax; ax = bx; bx = tmp;
        tmp = ay; ay = by; by = tmp;
        tmp = az; az = bz; bz = tmp;
        tmp = norma; norma = normb; normb = tmp;
    }
    if (normb>norma*cosalpha){
        float cx = ax-bx;
        float cy = ay-by;
        float cz = az-bz;
        float crossx = by*cz-bz*cy;
        float crossy = bz*cx-bx*cz;
        float crossz = bx*cy-by*cx;
        float t1 = crossx*crossx+crossy*crossy+crossz*crossz;
        float t2 = cx*cx+cy*cy+cz*cz;
        r0 = 2*sqrtf(t1/t2);
    }
    else r0 = 2*normb;
    return r0;
}

