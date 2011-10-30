
/* Include files */
#include <windows.h>
#include <stdio.h>
#include <conio.h>
#include "cbw.h"
#include "mex.h"   //--This one is required

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    static WORD * ADData;
    static int boardNum = 0;
    static int samples = 30000;
    static long rate = 1000;
    static int gain = BIP5VOLTS;
    static int allocated = 0;
    static int histStart;
    static int histAlign;
    static int histEnd;
    int i;

    int ULStat;
    unsigned options;
        
    short Status;
    long CurCount;
    long CurIndex;
    double * out;
    int arg;
    int len;
    
    if (!ADData) {
        ADData = (WORD*)cbWinBufAlloc(samples);
        options = BACKGROUND + CONTINUOUS + SINGLEIO;
    
        histStart = -1;
        histEnd = -1;
        histAlign = -1;
        
        ULStat = cbStopBackground(boardNum,AIFUNCTION);
        ULStat = cbAInScan (boardNum, 0, 2, samples, &rate, gain, ADData, options);
        return;
    }
        
    ULStat = cbGetStatus(boardNum, &Status, &CurCount, &CurIndex, AIFUNCTION);
    if (nrhs > 0) {
        arg = (int) *mxGetPr(prhs[0]);

        if (arg <= 0) {
            switch (arg) {
                case -4:
                    ULStat = cbStopBackground(boardNum,AIFUNCTION);
                    cbWinBufFree((int)ADData);
                    ADData = NULL;
                    return;
                    
                case -3:
                    histStart = CurIndex;
                    if (histStart == 0) {
                        histStart = samples;
                    }
                    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
                    *mxGetPr(plhs[0]) = histStart;
                    break;
                case -2:
                    histAlign = CurIndex;                   
                    if (histAlign == 0) {
                        histAlign = samples;
                    }
                    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
                    *mxGetPr(plhs[0]) = histAlign;
                    break;                    
                case -1:
                    histEnd = CurIndex;
                    if (histEnd == 0) {
                        histEnd = samples;
                    }
                    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
                    *mxGetPr(plhs[0]) = histEnd;
                    break;
                default:
                    if (histEnd == -1) {
                        histEnd = CurIndex;
                    }
                    if (histStart == -1) {
                        plhs[0] = mxCreateDoubleMatrix(0,1,mxREAL);
                        return;
                    }
                    
                    if (histEnd >= histStart) {
                        len = (histEnd - histStart)/3;
                        plhs[0] = mxCreateDoubleMatrix(len,1,mxREAL);
                        plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);
                        
                        out = mxGetPr(plhs[0]);

                        if (histAlign == -1) {
                            *mxGetPr(plhs[1]) = 0;
                        }
                        else {
                            *mxGetPr(plhs[1]) = (histAlign - histStart)/3;
                        }
                        
                        for (i = 0; i < len; i++) {
                            ULStat = cbToEngUnits32 (boardNum, gain, ADData[histStart-1+i*3], out+i);  
                        }
                    } else {
                        len = (histEnd+samples - histStart)/3;
                        plhs[0] = mxCreateDoubleMatrix(len,1,mxREAL);
                        plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);
                       
                        out = mxGetPr(plhs[0]);

                        if (histAlign == -1) {
                            i = 0;
                        }
                        else {
                            i = (histAlign-histStart)/3;
                            if (i < 0) {
                                i = samples/3 + i;
                            }
                        }
                        *mxGetPr(plhs[1]) = i;
                        
                        CurIndex = histStart;
                        
                        for (i = 0; i < len; i++) {
                            if (CurIndex == 0) {
                                CurIndex = samples;
                            }
                            ULStat = cbToEngUnits32 (boardNum, gain, ADData[(CurIndex-1)%samples], out+i);
                            
                            CurIndex += 3;
                        }                          
                    }
                    
                    histStart = -1;
                    histEnd = -1;
                    histAlign = -1;
                                        
                    break;
            }
        } else {
            plhs[0] = mxCreateDoubleMatrix(arg,2,mxREAL);
            out = mxGetPr(plhs[0]);
                        
            for (i = 0; i < arg; i++) {
                if (CurIndex == 0) {
                    CurIndex = samples;
                }
                
                ULStat = cbToEngUnits32 (boardNum, gain, ADData[CurIndex-2], out+i+arg);
                ULStat = cbToEngUnits32 (boardNum, gain, ADData[CurIndex-3], out+i);        

                CurIndex -= 3;                
            }
        }
    }
    else {
        plhs[0] = mxCreateDoubleMatrix(1,2,mxREAL);
        out = mxGetPr(plhs[0]);

        if (CurIndex == 0) {
            CurIndex = samples;
        }    
        ULStat = cbToEngUnits32 (boardNum, gain, ADData[CurIndex-2], out+1);
        ULStat = cbToEngUnits32 (boardNum, gain, ADData[CurIndex-3], out);        
    }
    
}
        



