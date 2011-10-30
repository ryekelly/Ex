% function digCode(codes)
%
% outputs digital codes to the bytes FIRSTPORTA and FIRSTPORTB, sending 
% sync pulses to the first bit of FIRSTPORTC.  Can send a vector of doubles
% or characters.
%
% recompile with this command:
% mex digCode.c cbw32.lib