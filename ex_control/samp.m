% function samp(arg)
%
% if background sampling is not running, samp always simply starts the timer and returns nothing.
%
% samp() returns the current eye position (x,y)
% samp(n) where n is positive returns the last n eye positions in a [n x 2] matrix
%
% samp(-3) marks the start of a histogram run and returns the index in the buffer (index for debugging only)
% samp(-2) marks the histogram align point and returns the index in the buffer (index for debugging only)
% samp(-1) marks the histogram end point and returns the index in the buffer (index for debugging only)
% samp(0) returns [h a], where h is the histogram from start to end
%
% samp(-4) stops the background sampling and frees the memory.
%
% NOTE: the buffer is 10 seconds long, so if the total time recording a hist 
% exceeds this there will be unexpected results.  Make the buffer longer if you
% anticipate >10s trials.  This is in samp.c, under the variable "samples".  It 
% MUST be a multiple of 3.  Right now it is 30000, which is 10000 samples for 3 
% channels.  So for 30 seconds you'd make it 90000.  I don't know how this affects 
% performance.  It may not.
