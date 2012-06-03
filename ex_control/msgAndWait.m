function msgAndWait(m,args)
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

if nargin > 1
    m = sprintf(m, args);
end

msg(m);

first_arg = strtok(m);

rcvd = '';
while ~strcmp(rcvd, first_arg)
    rcvd = waitFor();
end