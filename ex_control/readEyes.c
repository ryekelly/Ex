
/* Include files */
#include <windows.h>
#include <stdio.h>
#include <conio.h>
#include "cbw.h"
#include "mex.h"   //--This one is required

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int boardNum = 0;
    int ULStat;
    char ErrMsg[ERRSTRLEN];
    int gain = BIP5VOLTS;
    WORD DataValue = 0;
    float chA, chB;
          
    ULStat = cbAIn (boardNum, 0, gain, &DataValue);
    ULStat = cbToEngUnits (boardNum, gain, DataValue, &chA);
    ULStat = cbAIn (boardNum, 1, gain, &DataValue);
    ULStat = cbToEngUnits (boardNum, gain, DataValue, &chB);
    
    plhs[0] = mxCreateDoubleMatrix(1,2,mxREAL);
    mxGetPr(plhs[0])[0] = chA;
    mxGetPr(plhs[0])[1] = chB;
}
        



