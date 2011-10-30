
/* Include files */
#include <windows.h>
#include <stdio.h>
#include <conio.h>
#include "cbw.h"
#include "mex.h"   //--This one is required

extern WORD * ADData;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    static int boardNum;
    static int samples;
    static long rate;
    static int gain;

    int ULStat;
    char ErrMsg[ERRSTRLEN];
    int i;
    double * out;

    short Status;
    long CurCount;
    long CurIndex;
    
    mexPrintf("%p\n",ADData);
    
    ULStat = cbGetStatus(boardNum, &Status, &CurCount, &CurIndex, AIFUNCTION);
    
    plhs[0] = mxCreateDoubleMatrix(1,3,mxREAL);
    out = mxGetPr(plhs[0]);
    out[2] = CurIndex;
    out[1] = CurIndex-1;
    out[0] = CurIndex-2;
       
    
/*    for (i = 0; i < samples; i++)
    {
        ULStat = cbToEngUnits32 (boardNum, gain, ADData[i], out + i);
    }
    
    ULStat = cbStopBackground(boardNum,AIFUNCTION);*/
}
        



