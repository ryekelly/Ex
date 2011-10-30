/*ULDO01.C****************************************************************

File:                         ULDO01.C

Library Call Demonstrated:    cbDOut()

Purpose:                      Writes a bit to a digital output port.

Demonstration:                Configures FIRSTPORTA for output and
                              writes a value to the port.

Other Library Calls:          cbDConfigPort()
                              cbErrHandling()

Special Requirements:         Board 0 must have a digital output port.


Copyright (c) 1995-2002, Measurement Computing Corp.
All Rights Reserved.
***************************************************************************/


/* Include files */
#include <windows.h>
#include <stdio.h>
#include <conio.h>
#include "cbw.h"
#include "mex.h"   //--This one is required

void waitMS(float ms,LARGE_INTEGER frequency)
{
    LARGE_INTEGER t1, t2;           // ticks

    QueryPerformanceCounter(&t1);
    do
    {
        QueryPerformanceCounter(&t2);            
    }
    while ((t2.QuadPart - t1.QuadPart) * 1000.0 / frequency.QuadPart < ms);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int i;
    int boardNum = 0;
    int ULStat;
    int reward;
    LARGE_INTEGER frequency;        // ticks per second
    char ErrMsg[ERRSTRLEN];
    float duration;
    
    // get ticks per second
    QueryPerformanceFrequency(&frequency);

    if (nrhs > 0)
    {
        duration = *mxGetPr(prhs[0]);
    }
    else
    {
        duration = 20; /* 20 ms default */
    }

    ULStat = cbDOut(boardNum, AUXPORT,2);
    waitMS(duration,frequency);
    ULStat = cbDOut(boardNum, AUXPORT,0);

    return;
}
        



