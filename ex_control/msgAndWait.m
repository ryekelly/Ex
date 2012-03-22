function msgAndWait(msg,args)
% function msg(msg,args)
% ex helper function, sends a message to the slave and then waits for a
% response from the slave
%
% msg: a string message
% args: if present, the msg variable can use % replacement like fprintf and
%   these are the arguments
%
% examples:
% > msg('obj_on 3');
% > msg('obj_on %i',3);

global out;

if nargin > 1
    fprintf(out,msg,args);
    % uncomment for debugging
    disp(msg);
    disp(args);
else
    fprintf(out,msg);
    % uncomment for debugging
    disp(msg);
end

prefix = strtok(msg);

waitFor(prefix);
